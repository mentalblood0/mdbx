require "./LibMdbx.cr"

module Mdbx
  alias P = Pointer(Void)
  alias K = Bytes
  alias V = Bytes
  alias KV = {K, V}

  class Exception < Exception
    def self.from_code(e : LibMdbx::Error, src : String)
      self.new src + ": (#{e.value} #{e}) #{String.new LibMdbx.strerror e}"
    end
  end

  class Api
    macro mcec(src, b)
      ev = {{b}}
      raise Exception.from_code ev, {{src}} unless ev == LibMdbx::Error::MDBX_SUCCESS
    end

    def self.env_create : P
      r = P.new 0_u64
      mcec "env_create(#{pointerof(r)})", LibMdbx.env_create pointerof(r)
      r
    end

    def self.env_open(env : P, path : Path, flags : LibMdbx::EnvFlags, mode : LibC::ModeT) : Nil
      mcec "env_open(#{env}, \"#{path}\", #{flags}, #{mode})", LibMdbx.env_open env, path.to_s.to_unsafe, flags, mode
    end

    def self.env_close(env : P)
      mcec "env_close(#{env})", LibMdbx.env_close env
    end

    def self.txn_begin(env : P, parent : P?, flags : LibMdbx::TxnFlags) : P
      r = P.new 0_u64
      mcec "txn_begin(#{env}, #{parent}, #{flags}, #{pointerof(r)})", LibMdbx.txn_begin env, parent ? parent : P.null, flags, pointerof(r)
      r
    end

    def self.dbi_open(txn : P, name : String?, flags : LibMdbx::DbFlags) : LibMdbx::Dbi
      r = LibMdbx::Dbi.new 0
      mcec "dbi_open(#{txn}, #{name}, #{flags}, #{pointerof(r)})", LibMdbx.dbi_open txn, name ? name.to_unsafe : Pointer(LibC::Char).null, flags, pointerof(r)
      r
    end

    def self.dbi_close(env : P, dbi : LibMdbx::Dbi)
      mcec "dbi_close(#{env}, #{dbi})", LibMdbx.dbi_close env, dbi
    end

    def self.drop(txn : P, dbi : LibMdbx::Dbi, del : Bool)
      mcec "drop(#{txn}, #{dbi}, #{del})", LibMdbx.drop txn, dbi, del
    end

    def self.put(txn : P, dbi : LibMdbx::Dbi, k : Bytes, v : Bytes, flags : LibMdbx::PutFlags) : Nil
      ks = uninitialized LibMdbx::Val
      ks.iov_base = k.to_unsafe
      ks.iov_len = k.size
      vs = uninitialized LibMdbx::Val
      vs.iov_base = v.to_unsafe
      vs.iov_len = v.size
      mcec "put(#{txn}, #{dbi}, #{ks}, #{vs}, #{flags})", LibMdbx.put txn, dbi, pointerof(ks), pointerof(vs), flags
    end

    def self.del(txn : P, dbi : LibMdbx::Dbi, k : Bytes, v : Bytes?) : Nil
      ks = uninitialized LibMdbx::Val
      ks.iov_base = k.to_unsafe
      ks.iov_len = k.size
      if v
        vs = uninitialized LibMdbx::Val
        vs.iov_base = v.to_unsafe
        vs.iov_len = v.size
        mcec "del(#{txn}, #{dbi}, #{ks}, #{vs})", LibMdbx.del txn, dbi, pointerof(ks), pointerof(vs)
      else
        mcec "del(#{txn}, #{dbi}, #{ks}, NULL)", LibMdbx.del txn, dbi, pointerof(ks), Pointer(LibMdbx::Val).null
      end
    end

    def self.get(txn : P, dbi : LibMdbx::Dbi, k : Bytes) : Bytes
      ks = uninitialized LibMdbx::Val
      ks.iov_base = k.to_unsafe
      ks.iov_len = k.size
      vs = uninitialized LibMdbx::Val
      mcec "get(#{txn}, #{dbi}, #{ks}, #{vs})", LibMdbx.get txn, dbi, pointerof(ks), pointerof(vs)
      Bytes.new Pointer(UInt8).new(vs.iov_base.address), vs.iov_len
    end

    def self.txn_commit(txn : P) : Nil
      mcec "txn_commit(#{txn})", LibMdbx.txn_commit txn
    end

    def self.txn_abort(txn : P)
      mcec "txn_abort(#{txn})", LibMdbx.txn_abort txn
    end

    def self.cursor_open(txn : P, dbi : LibMdbx::Dbi) : P
      r = P.new 0_u64
      mcec "cursor_open(#{txn}, #{dbi})", LibMdbx.cursor_open txn, dbi, pointerof(r)
      r
    end

    def self.cursor_close(cursor : P)
      mcec "cursor_close(#{cursor})", LibMdbx.cursor_close cursor
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
        mcec "cursor_get(#{cursor}, #{op})", e
      end

      {Bytes.new(Pointer(UInt8).new(ks.iov_base.address), ks.iov_len),
       Bytes.new(Pointer(UInt8).new(vs.iov_base.address), vs.iov_len)}
    end
  end

  class Env
    getter env : P
    getter txn : P?

    def initialize(path : Path, flags : LibMdbx::EnvFlags = LibMdbx::EnvFlags::MDBX_NOSUBDIR | LibMdbx::EnvFlags::MDBX_LIFORECLAIM, mode : LibC::ModeT = 0o664)
      @env = Api.env_create
      Api.env_open @env, path, flags, mode
    end

    protected def initialize(@env, @txn)
    end

    def transaction(flags : LibMdbx::TxnFlags = LibMdbx::TxnFlags.new(0), &)
      ctxn = Api.txn_begin @env, @txn, flags
      begin
        yield Env.new @env, ctxn
      rescue ex
        Api.txn_abort ctxn
        raise ex
      else
        Api.txn_commit ctxn
      end
    end

    def db(name : String? = nil, flags : LibMdbx::DbFlags = LibMdbx::DbFlags.new(0))
      Db.new @txn.not_nil!, Api.dbi_open @txn.not_nil!, name, flags
    end

    def close(db : Db)
      Api.dbi_close @env, db.dbi
    end

    def clear(db : Db)
      Api.drop @txn.not_nil!, db.dbi, false
    end

    def drop(db : Db)
      Api.drop @txn.not_nil!, db.dbi, true
    end

    def finalize
      Api.env_close @env unless @txn
    end
  end

  class Db
    getter dbi : LibMdbx::Dbi

    @txn : P

    def initialize(@txn, @dbi)
    end

    def put(k : K, v : V, flags : LibMdbx::PutFlags)
      Api.put @txn.not_nil!, @dbi, k, v, flags
    end

    def insert(k : K, v : V)
      put k, v, LibMdbx::PutFlags::MDBX_NOOVERWRITE
    end

    def upsert(k : K, v : V)
      put k, v, LibMdbx::PutFlags::MDBX_UPSERT
    end

    def update(k : K, v : V)
      put k, v, LibMdbx::PutFlags::MDBX_CURRENT
    end

    def delete(k : K, v : V? = nil)
      Api.del @txn.not_nil!, @dbi, k, v
    end

    def get(k : K)
      Api.get @txn.not_nil!, @dbi, k
    end

    def cursor
      Cursor.new Api.cursor_open @txn.not_nil!, @dbi
    end

    def each(&)
      c = self.cursor
      while kv = c.next
        yield kv
      end
    end

    def all
      r = [] of KV
      each { |kv| r << kv }
      r
    end

    def from!(k : K, &)
      c = self.cursor
      if kv = c.on! k
        yield kv
      else
        return
      end
      while kv = c.next
        yield kv
      end
    end

    def from!(k : K)
      r = [] of KV
      from!(k) { |kv| r << kv }
      r
    end

    def from(k : K, v : V? = nil, &)
      c = self.cursor
      if kv = c.on k, v
        yield kv
      else
        return
      end
      while kv = c.next
        yield kv
      end
    end

    def from(k : K, v : V? = nil)
      r = [] of KV
      from(k, v) { |kv| r << kv }
      r
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
