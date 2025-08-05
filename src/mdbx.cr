require "./LibMdbx.cr"

module Mdbx
  alias P = Pointer(Void)

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

    def self.env_open(env : P, path : String, flags : LibMdbx::EnvFlags, mode : LibC::ModeT) : Nil
      check_error_code "env_open(#{env}, \"#{path}\", #{flags}, #{mode})", LibMdbx.env_open env, path.to_unsafe, flags, mode
    end

    def self.env_close(env : P)
      check_error_code "env_close(#{env})", LibMdbx.env_close env
    end

    def self.txn_begin(env : P, parent : P, flags : LibMdbx::TxnFlags) : P
      r = P.new 0_u64
      check_error_code "txn_begin(#{env}, #{parent}, #{flags}, #{pointerof(r)})", LibMdbx.txn_begin env, parent, flags, pointerof(r)
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
      check_error_clode "txn_abort(#{txn})", LibMdbx.txn_abort txn
    end

    def self.cursor_open(txn : P, dbi : LibMdbx::Dbi) : P
      r = P.new 0_u64
      check_error_code "cursor_open(#{txn}, #{dbi})", LibMdbx.cursor_open txn, dbi, pointerof(r)
      r
    end

    def self.cursor_close(cursor : P)
      check_error_code "cursor_close(#{cursor})", LibMdbx.cursor_close cursor
    end

    def self.cursor_get(cursor : P, op : LibMdbx::CursorOp) : {key: Bytes, value: Bytes}?
      ks = uninitialized LibMdbx::Val
      vs = uninitialized LibMdbx::Val

      case e = LibMdbx.cursor_get cursor, pointerof(ks), pointerof(vs), op
      when LibMdbx::Error::MDBX_NOTFOUND
        return nil
      when LibMdbx::Error::MDBX_SUCCESS
      else
        check_error_code "cursor_get(#{cursor}, #{op})", e
      end

      {key:   Bytes.new(Pointer(UInt8).new(ks.iov_base.address), ks.iov_len),
       value: Bytes.new(Pointer(UInt8).new(vs.iov_base.address), vs.iov_len)}
    end
  end
end
