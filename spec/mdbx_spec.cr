require "spec"

require "../src/mdbx.cr"

describe Mdbx do
  # it "example" do
  #   env = Mdbx::Api.env_create
  #   Mdbx::Api.env_open env, Path.new("/tmp/mdbx"), LibMdbx::EnvFlags::MDBX_NOSUBDIR | LibMdbx::EnvFlags::MDBX_LIFORECLAIM, 0o664_u32

  #   txn = Mdbx::Api.txn_begin env, nil, LibMdbx::TxnFlags.new 0
  #   dbi = Mdbx::Api.dbi_open txn, nil, LibMdbx::DbFlags.new 0

  #   k = "key".to_slice
  #   v = "value".to_slice
  #   Mdbx::Api.put txn, dbi, k, v, LibMdbx::PutFlags.new 0

  #   Mdbx::Api.txn_commit txn

  #   txn = Mdbx::Api.txn_begin env, Mdbx::P.null, LibMdbx::TxnFlags::MDBX_TXN_RDONLY
  #   cursor = Mdbx::Api.cursor_open txn, dbi
  #   kvs = {} of Bytes => Bytes
  #   while kv = Mdbx::Api.cursor_get cursor, LibMdbx::CursorOp::MDBX_NEXT
  #     kvs[kv[:key]] = kv[:value]
  #   end
  #   Mdbx::Api.cursor_close(cursor)
  #   kvs.should eq({k => v})

  #   Mdbx::Api.dbi_close env, dbi
  #   Mdbx::Api.env_close env
  # end

  it "wrapped example" do
    env = Mdbx::Env.new Path.new "/tmp/mdbx"

    kvs = (0..1).map { |i| {"key_#{i}".to_slice, "value_#{i}".to_slice} }
    env.transaction do |txn|
      kvs.each { |kv| txn.put txn.dbi, kv[0], kv[1] }
    end

    env.transaction do |txn|
      txn.each(txn.dbi).should eq(kvs)
      txn.from(txn.dbi, kvs[0][0]).should eq kvs
      txn.from(txn.dbi, kvs[1][0]).should eq kvs[1..]
      txn.from!(txn.dbi, kvs[0][0]).should eq kvs
      txn.from!(txn.dbi, kvs[1][0]).should eq kvs[1..]
      txn.from(txn.dbi, kvs[0][0], kvs[0][1]).should eq kvs
      txn.from(txn.dbi, kvs[1][0], kvs[1][1]).should eq kvs[1..]
    end
  end
end
