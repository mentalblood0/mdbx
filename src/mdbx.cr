require "./LibMdbx.cr"

module Mdbx
  alias P = Pointer(Void)
  alias K = Bytes
  alias V = Bytes
  alias KV = {K, V}

  class Exception < Exception
  end

  class Api
    def self.check_error_code(source : String, e : LibMdbx::Error)
      raise Exception.new "#{source}: (#{e.value} #{e}) #{String.new LibMdbx.strerror e}" if e != LibMdbx::Error::MDBX_SUCCESS
    end

    def self.env_create : P
      r = P.new 0_u64
      check_error_code "env_create(#{pointerof(r)})", LibMdbx.env_create pointerof(r)
      r
    end

    def self.env_open(env : P, path : Path, flags : LibMdbx::EnvFlags, mode : LibC::ModeT) : Nil
      check_error_code "env_open(#{env}, \"#{path}\", #{flags}, #{mode})", LibMdbx.env_open env, path.to_s.to_unsafe, flags, mode
    end

    def self.env_close(env : P)
      check_error_code "env_close(#{env})", LibMdbx.env_close env
    end

    def self.txn_begin(env : P, parent : P?, flags : LibMdbx::TxnFlags) : P
      r = P.new 0_u64
      check_error_code "txn_begin(#{env}, #{parent}, #{flags}, #{pointerof(r)})", LibMdbx.txn_begin env, parent ? parent : P.null, flags, pointerof(r)
      r
    end

    def self.dbi_open(txn : P, name : String?, flags : LibMdbx::DbFlags) : LibMdbx::Dbi
      r = LibMdbx::Dbi.new 0
      check_error_code "dbi_open(#{txn}, #{name}, #{flags}, #{pointerof(r)})", LibMdbx.dbi_open txn, name ? name.to_unsafe : Pointer(LibC::Char).null, flags, pointerof(r)
      r
    end

    def self.dbi_close(env : P, dbi : LibMdbx::Dbi)
      check_error_code "dbi_close(#{env}, #{dbi})", LibMdbx.dbi_close env, dbi
    end

    def self.put(txn : P, dbi : LibMdbx::Dbi, k : Bytes, v : Bytes, flags : LibMdbx::PutFlags) : Nil
      ks = uninitialized LibMdbx::Val
      ks.iov_base = k.to_unsafe
      ks.iov_len = k.size
      vs = uninitialized LibMdbx::Val
      vs.iov_base = v.to_unsafe
      vs.iov_len = v.size
      check_error_code "put(#{txn}, #{dbi}, #{ks}, #{vs}, #{flags})", LibMdbx.put txn, dbi, pointerof(ks), pointerof(vs), flags
    end

    def self.txn_commit(txn : P) : Nil
      check_error_code "txn_commit(#{txn})", LibMdbx.txn_commit txn
    end

    def self.txn_abort(txn : P)
      check_error_code "txn_abort(#{txn})", LibMdbx.txn_abort txn
    end

    def self.cursor_open(txn : P, dbi : LibMdbx::Dbi) : P
      r = P.new 0_u64
      check_error_code "cursor_open(#{txn}, #{dbi})", LibMdbx.cursor_open txn, dbi, pointerof(r)
      r
    end

    def self.cursor_close(cursor : P)
      check_error_code "cursor_close(#{cursor})", LibMdbx.cursor_close cursor
    end

    def self.cursor_get(cursor : P, op : LibMdbx::CursorOp, k : Bytes? = nil, v : Bytes? = nil) : KV?
      ks = LibMdbx::Val.new
      if k
        ks.iov_base = k.to_unsafe
        ks.iov_len = k.size
      end
      vs = LibMdbx::Val.new
      if v
        vs.iov_base = v.to_unsafe
        vs.iov_len = v.size
      end

      case e = LibMdbx.cursor_get cursor, pointerof(ks), pointerof(vs), op
      when LibMdbx::Error::MDBX_NOTFOUND
        return nil
      when LibMdbx::Error::MDBX_SUCCESS
      else
        check_error_code "cursor_get(#{cursor}, #{op})", e
      end

      {Bytes.new(Pointer(UInt8).new(ks.iov_base.address), ks.iov_len),
       Bytes.new(Pointer(UInt8).new(vs.iov_base.address), vs.iov_len)}
    end
  end

  class Env
    getter path : Path
    getter flags : LibMdbx::EnvFlags
    getter mode : LibC::ModeT

    @env : P
    property need_finalize : Bool = true
    property txn : P?

    def initialize(@path : Path, @flags : LibMdbx::EnvFlags = LibMdbx::EnvFlags::MDBX_NOSUBDIR | LibMdbx::EnvFlags::MDBX_LIFORECLAIM, @mode : LibC::ModeT = 0o664)
      @env = Api.env_create
      Api.env_open @env, @path, @flags, @mode
    end

    def transaction(flags : LibMdbx::TxnFlags = LibMdbx::TxnFlags.new(0), &)
      txn = Api.txn_begin @env, @txn, flags
      r = self.dup
      r.txn = txn
      r.need_finalize = false
      begin
        yield r
      rescue ex
        Api.txn_abort txn
        raise ex
      end
      Api.txn_commit txn
    end

    def dbi(name : String? = nil, flags : LibMdbx::DbFlags = LibMdbx::DbFlags.new(0))
      Api.dbi_open @txn.not_nil!, name, flags
    end

    def close(dbi : LibMdbx::Dbi)
      Api.dbi_close @env, dbi
    end

    def put(dbi : LibMdbx::Dbi, k : K, v : V, flags : LibMdbx::PutFlags = LibMdbx::PutFlags.new(0))
      Api.put @txn.not_nil!, dbi, k, v, flags
    end

    def cursor(dbi : LibMdbx::Dbi)
      Cursor.new Api.cursor_open @txn.not_nil!, dbi
    end

    def each(dbi : LibMdbx::Dbi, &)
      c = self.cursor dbi
      while kv = c.next
        yield kv
      end
    end

    def each(dbi : LibMdbx::Dbi)
      r = [] of KV
      each(dbi) { |kv| r << kv }
      r
    end

    def from!(dbi : LibMdbx::Dbi, k : K, &)
      c = self.cursor dbi
      if kv = c.on! k
        yield kv
      else
        return
      end
      while kv = c.next
        yield kv
      end
    end

    def from!(dbi : LibMdbx::Dbi, k : K)
      r = [] of KV
      from!(dbi, k) { |kv| r << kv }
      r
    end

    def from(dbi : LibMdbx::Dbi, k : K, v : V? = nil, &)
      c = self.cursor dbi
      if kv = c.on k, v
        yield kv
      else
        return
      end
      while kv = c.next
        yield kv
      end
    end

    def from(dbi : LibMdbx::Dbi, k : K, v : V? = nil)
      r = [] of KV
      from(dbi, k, v) { |kv| r << kv }
      r
    end

    def finalize
      Api.env_close @env if @need_finalize
    end
  end

  class Cursor
    getter data : KV?

    protected def initialize(@c : P)
    end

    def next : KV?
      @data = Api.cursor_get @c, LibMdbx::CursorOp::MDBX_NEXT
    end

    def prev : KV?
      @data = Api.cursor_get @c, LibMdbx::CursorOp::MDBX_PREV
    end

    def on!(k : K) : KV?
      @data = Api.cursor_get @c, LibMdbx::CursorOp::MDBX_SET_KEY, k
    end

    def on(k : K) : KV?
      @data = Api.cursor_get @c, LibMdbx::CursorOp::MDBX_SET_RANGE, k
    end

    def on(k : K, v : V?) : KV?
      if v
        @data = Api.cursor_get @c, LibMdbx::CursorOp::MDBX_SET_LOWERBOUND, k, v
      else
        on k
      end
    end

    def finalize
      Api.cursor_close @c
    end
  end
end
