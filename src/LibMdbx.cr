@[Link(ldflags: "#{__DIR__}/libmdbx/mdbx-static.o")]
lib LibMdbx
  enum Error
    MDBX_SUCCESS               = 0
    MDBX_RESULT_FALSE          = MDBX_SUCCESS
    MDBX_RESULT_TRUE           =     -1
    MDBX_KEYEXIST              = -30799
    MDBX_FIRST_LMDB_ERRCODE    = MDBX_KEYEXIST
    MDBX_NOTFOUND              = -30798
    MDBX_PAGE_NOTFOUND         = -30797
    MDBX_CORRUPTED             = -30796
    MDBX_PANIC                 = -30795
    MDBX_VERSION_MISMATCH      = -30794
    MDBX_INVALID               = -30793
    MDBX_MAP_FULL              = -30792
    MDBX_DBS_FULL              = -30791
    MDBX_READERS_FULL          = -30790
    MDBX_TXN_FULL              = -30788
    MDBX_CURSOR_FULL           = -30787
    MDBX_PAGE_FULL             = -30786
    MDBX_UNABLE_EXTEND_MAPSIZE = -30785
    MDBX_INCOMPATIBLE          = -30784
    MDBX_BAD_RSLOT             = -30783
    MDBX_BAD_TXN               = -30782
    MDBX_BAD_VALSIZE           = -30781
    MDBX_BAD_DBI               = -30780
    MDBX_PROBLEM               = -30779
    MDBX_LAST_LMDB_ERRCODE     = MDBX_PROBLEM
    MDBX_BUSY                  = -30778
    MDBX_FIRST_ADDED_ERRCODE   = MDBX_BUSY
    MDBX_EMULTIVAL             = -30421
    MDBX_EBADSIGN              = -30420
    MDBX_WANNA_RECOVERY        = -30419
    MDBX_EKEYMISMATCH          = -30418
    MDBX_TOO_LARGE             = -30417
    MDBX_THREAD_MISMATCH       = -30416
    MDBX_TXN_OVERLAPPING       = -30415
    MDBX_BACKLOG_DEPLETED      = -30414
    MDBX_DUPLICATED_CLK        = -30413
    MDBX_DANGLING_DBI          = -30412
    MDBX_OUSTED                = -30411
    MDBX_MVCC_RETARDED         = -30410
    MDBX_LAST_ADDED_ERRCODE    = MDBX_MVCC_RETARDED
  end

  @[Flags]
  enum EnvFlags : UInt32
    MDBX_ENV_DEFAULTS    =          0
    MDBX_VALIDATION      = 0x00002000
    MDBX_NOSUBDIR        =     0x4000
    MDBX_RDONLY          =    0x20000
    MDBX_EXCLUSIVE       =   0x400000
    MDBX_ACCEDE          = 0x40000000
    MDBX_WRITEMAP        =    0x80000
    MDBX_NOSTICKYTHREADS =   0x200000
    MDBX_NORDAHEAD       =   0x800000
    MDBX_NOMEMINIT       =  0x1000000
    MDBX_LIFORECLAIM     =  0x4000000
    MDBX_PAGEPERTURB     =  0x8000000
    MDBX_SYNC_DURABLE    =          0
    MDBX_NOMETASYNC      =    0x40000
    MDBX_SAFE_NOSYNC     =    0x10000
    MDBX_MAPASYNC        = MDBX_SAFE_NOSYNC
    MDBX_UTTERLY_NOSYNC  = MDBX_SAFE_NOSYNC | 0x100000_u32
  end

  @[Flags]
  enum TxnFlags
    MDBX_TXN_READWRITE      = 0
    MDBX_TXN_RDONLY         = EnvFlags::MDBX_RDONLY
    MDBX_TXN_RDONLY_PREPARE = EnvFlags::MDBX_RDONLY | EnvFlags::MDBX_NOMEMINIT
    MDBX_TXN_TRY            = 0x10000000
    MDBX_TXN_NOMETASYNC     = EnvFlags::MDBX_NOMETASYNC
    MDBX_TXN_NOSYNC         = EnvFlags::MDBX_SAFE_NOSYNC
    MDBX_TXN_INVALID        = Int32::MIN
    MDBX_TXN_FINISHED       = 0x01
    MDBX_TXN_ERROR          = 0x02
    MDBX_TXN_DIRTY          = 0x04
    MDBX_TXN_SPILLS         = 0x08
    MDBX_TXN_HAS_CHILD      = 0x10
    MDBX_TXN_PARKED         = 0x20
    MDBX_TXN_AUTOUNPARK     = 0x40
    MDBX_TXN_OUSTED         = 0x80
    MDBX_TXN_BLOCKED        = MDBX_TXN_FINISHED | MDBX_TXN_ERROR | MDBX_TXN_HAS_CHILD | MDBX_TXN_PARKED
  end

  @[Flags]
  enum DbFlags : UInt32
    MDBX_DB_DEFAULTS =       0
    MDBX_REVERSEKEY  =    0x02
    MDBX_DUPSORT     =    0x04
    MDBX_INTEGERKEY  =    0x08
    MDBX_DUPFIXED    =    0x10
    MDBX_INTEGERDUP  =    0x20
    MDBX_REVERSEDUP  =    0x40
    MDBX_CREATE      = 0x40000
    MDBX_DB_ACCEDE   = EnvFlags::MDBX_ACCEDE
  end

  @[Flags]
  enum PutFlags : UInt32
    MDBX_UPSERT      =       0
    MDBX_NOOVERWRITE =    0x10
    MDBX_NODUPDATA   =    0x20
    MDBX_CURRENT     =    0x40
    MDBX_ALLDUPS     =    0x80
    MDBX_RESERVE     = 0x10000
    MDBX_APPEND      = 0x20000
    MDBX_APPENDDUP   = 0x40000
    MDBX_MULTIPLE    = 0x80000
  end

  alias Dbi = UInt32

  struct Val
    iov_base : Void*
    iov_len : LibC::SizeT
  end

  enum CursorOp
    MDBX_FIRST
    MDBX_FIRST_DUP
    MDBX_GET_BOTH
    MDBX_GET_BOTH_RANGE
    MDBX_GET_CURRENT
    MDBX_GET_MULTIPLE
    MDBX_LAST
    MDBX_LAST_DUP
    MDBX_NEXT
    MDBX_NEXT_DUP
    MDBX_NEXT_MULTIPLE
    MDBX_NEXT_NODUP
    MDBX_PREV
    MDBX_PREV_DUP
    MDBX_PREV_NODUP
    MDBX_SET
    MDBX_SET_KEY
    MDBX_SET_RANGE
    MDBX_PREV_MULTIPLE
    MDBX_SET_LOWERBOUND
    MDBX_SET_UPPERBOUND
    MDBX_TO_KEY_LESSER_THAN
    MDBX_TO_KEY_LESSER_OR_EQUAL
    MDBX_TO_KEY_EQUAL
    MDBX_TO_KEY_GREATER_OR_EQUAL
    MDBX_TO_KEY_GREATER_THAN
    MDBX_TO_EXACT_KEY_VALUE_LESSER_THAN
    MDBX_TO_EXACT_KEY_VALUE_LESSER_OR_EQUAL
    MDBX_TO_EXACT_KEY_VALUE_EQUAL
    MDBX_TO_EXACT_KEY_VALUE_GREATER_OR_EQUAL
    MDBX_TO_EXACT_KEY_VALUE_GREATER_THAN
    MDBX_TO_PAIR_LESSER_THAN
    MDBX_TO_PAIR_LESSER_OR_EQUAL
    MDBX_TO_PAIR_EQUAL
    MDBX_TO_PAIR_GREATER_OR_EQUAL
    MDBX_TO_PAIR_GREATER_THAN
    MDBX_SEEK_AND_GET_MULTIPLE
  end

  fun strerror = mdbx_strerror(errnum : Int32) : LibC::Char*
  fun env_create = mdbx_env_create(penv : Void**) : Error
  fun env_open = mdbx_env_open(env : Void*, pathname : LibC::Char*, flags : EnvFlags, mode : LibC::ModeT) : Error
  fun env_close = mdbx_env_close(env : Void*) : Error
  fun txn_begin = mdbx_txn_begin(env : Void*, parent : Void*, flags : TxnFlags, txn : Void**) : Error
  fun dbi_open = mdbx_dbi_open(txn : Void*, name : LibC::Char*, flags : DbFlags, dbi : Dbi*) : Error
  fun dbi_close = mdbx_dbi_close(env : Void*, dbi : Dbi) : Error
  fun put = mdbx_put(txn : Void*, dbi : Dbi, key : Val*, data : Val*, flags : PutFlags) : Error
  fun del = mdbx_del(txn : Void*, dbi : Dbi, key : Val*, data : Val*) : Error
  fun txn_commit = mdbx_txn_commit(txn : Void*) : Error
  fun txn_abort = mdbx_txn_abort(txn : Void*) : Error
  fun cursor_open = mdbx_cursor_open(txn : Void*, dbi : Dbi, cursor : Void**) : Error
  fun cursor_get = mdbx_cursor_get(cursor : Void*, key : Val*, data : Val*, op : CursorOp) : Error
  fun cursor_close = mdbx_cursor_close(cursor : Void*) : Error
end
