require "spec"

require "../src/mdbx.cr"

describe Mdbx do
  env = Mdbx::Env.from_yaml <<-YAML
  path: /tmp/mdbx
  flags:
    - MDBX_NOSUBDIR
    - MDBX_LIFORECLAIM
  mode: 0o664
  db_flags:
    default:
      - MDBX_DB_DEFAULTS
      - MDBX_CREATE
  YAML
  dbi = LibMdbx::Dbi.new 0
  env.transaction { |tx| dbi = tx.dbi "default" }

  Spec.after_each do
    env.transaction { |tx| tx.clear tx.db dbi }
  end

  it "inserts" do
    env.transaction do |tx|
      db = tx.db dbi
      db.insert "key".to_slice, "value".to_slice
      expect_raises(Mdbx::Exception) do
        db.insert "key".to_slice, "value".to_slice
      end
    end
  end

  it "upserts" do
    env.transaction do |tx|
      db = tx.db dbi
      db.upsert "key".to_slice, "value".to_slice
      db.upsert "key".to_slice, "value".to_slice
    end
  end

  it "updates" do
    env.transaction do |tx|
      db = tx.db dbi
      db.insert "key".to_slice, "value".to_slice
      db.update "key".to_slice, "other".to_slice
      expect_raises(Mdbx::Exception) do
        db.update "other".to_slice, "value".to_slice
      end
    end
  end

  it "deletes" do
    env.transaction do |tx|
      db = tx.db dbi
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

  it "gets" do
    env.transaction do |tx|
      db = tx.db dbi
      db.insert "key".to_slice, "value".to_slice
      db.get("key".to_slice).should eq "value".to_slice
    end
  end

  it "does not leak", tags: "leakage" do
    k = ("a" * 1024).to_slice
    v = ("b" * 1024).to_slice
    loop do
      env.transaction { |tx| tx.db(dbi).insert k, v }
      env.transaction { |tx| tx.db(dbi).update k, v }
      env.transaction { |tx| tx.db(dbi).get k }
      env.transaction { |tx| tx.db(dbi).delete k }
      sleep 1.nanoseconds
    end
  end

  it "range-scans" do
    n = 100
    kvs = (0..n).map { |i| i.to_s.rjust(n.to_s.size).to_slice }.map { |i| {i, i} }
    env.transaction do |tx|
      db = tx.db dbi
      kvs.each { |k, v| db.insert k, v }
      db.all.should eq kvs
      (0..n).each { |i| db.from(kvs[i][0]).should eq kvs[i..] }
      (0..n).each { |i| db.from!(kvs[i][0]).should eq kvs[i..] }
      (0..n).each { |i| db.from(kvs[i][0], kvs[i][1]).should eq kvs[i..] }
    end
  end
end
