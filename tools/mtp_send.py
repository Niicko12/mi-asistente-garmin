import ctypes, os, sys

local, parent_id = sys.argv[1], int(sys.argv[2])
lib = ctypes.CDLL("/opt/homebrew/lib/libmtp.dylib")

class File(ctypes.Structure):
    pass
File._fields_ = [
    ("item_id", ctypes.c_uint32),
    ("parent_id", ctypes.c_uint32),
    ("storage_id", ctypes.c_uint32),
    ("filename", ctypes.c_char_p),
    ("filesize", ctypes.c_uint64),
    ("modificationdate", ctypes.c_long),
    ("filetype", ctypes.c_int),
    ("next", ctypes.POINTER(File)),
]

lib.LIBMTP_Init()
lib.LIBMTP_Get_First_Device.restype = ctypes.c_void_p
lib.LIBMTP_Get_Filemetadata.restype = ctypes.POINTER(File)
lib.LIBMTP_Get_Filemetadata.argtypes = [ctypes.c_void_p, ctypes.c_uint32]
lib.LIBMTP_Send_File_From_File.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.POINTER(File), ctypes.c_void_p, ctypes.c_void_p]
lib.LIBMTP_Release_Device.argtypes = [ctypes.c_void_p]
lib.LIBMTP_Dump_Errorstack.argtypes = [ctypes.c_void_p]

dev = lib.LIBMTP_Get_First_Device()
if not dev:
    sys.exit("no device")
try:
    parent = lib.LIBMTP_Get_Filemetadata(dev, parent_id)
    if not parent:
        sys.exit("parent folder not found")
    meta = File()
    meta.parent_id = parent_id
    meta.storage_id = parent.contents.storage_id
    meta.filename = os.path.basename(local).encode()
    meta.filesize = os.path.getsize(local)
    meta.filetype = 44  # LIBMTP_FILETYPE_UNKNOWN
    rc = lib.LIBMTP_Send_File_From_File(dev, local.encode(), ctypes.byref(meta), None, None)
    if rc != 0:
        lib.LIBMTP_Dump_Errorstack(dev)
        sys.exit("send failed")
    print("sent", meta.filename.decode(), "item", meta.item_id, "storage", hex(meta.storage_id))
finally:
    lib.LIBMTP_Release_Device(dev)
