require "spec"

require "../src/mdbx.cr"

describe Mdbx do
  env = Mdbx::Env.new Path.new "/tmp/mdbx"

  Spec.after_each do
    env.transaction { |tx| tx.clear tx.db }
  end

  it "inserts" do
    env.transaction do |tx|
      db = tx.db
      db.insert "key".to_slice, "value".to_slice
      expect_raises(Mdbx::Exception) do
        db.insert "key".to_slice, "value".to_slice
      end
    end
  end

  it "upserts" do
    env.transaction do |tx|
      db = tx.db
      db.upsert "key".to_slice, "value".to_slice
      db.upsert "key".to_slice, "value".to_slice
    end
  end

  it "updates" do
    env.transaction do |tx|
      db = tx.db
      db.insert "key".to_slice, "value".to_slice
      db.update "key".to_slice, "other".to_slice
      expect_raises(Mdbx::Exception) do
        db.update "other".to_slice, "value".to_slice
      end
    end
  end

  it "deletes" do
    env.transaction do |tx|
      db = tx.db
      expect_raises(Mdbx::Exception) do
        db.delete "key".to_slice
      end
      db.insert "key".to_slice, "value".to_slice
      expect_raises(Mdbx::Exception) do
        db.delete "key".to_slice, "other".to_slice
      end
      db.delete "key".to_slice
      db.insert "key".to_slice, "value".to_slice
      db.delete "key".to_slice, "value".to_slice
    end
  end

  it "range-scans" do
    kvs = (0..4).map { |i| {"key_#{i}".to_slice, "value_#{i}".to_slice} }
    env.transaction do |tx|
      db = tx.db
      kvs.each { |k, v| db.insert k, v }
    end

    env.transaction do |tx|
      db = tx.db
      db.all.should eq kvs
      db.from(kvs[0][0]).should eq kvs
      db.from(kvs[2][0]).should eq kvs[2..]
      db.from!(kvs[0][0]).should eq kvs
      db.from!(kvs[2][0]).should eq kvs[2..]
      db.from(kvs[0][0], kvs[0][1]).should eq kvs
      db.from(kvs[2][0], kvs[1][1]).should eq kvs[2..]
    end
  end
end
