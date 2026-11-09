"""Read the Windows Cloud Files provider's in-sync flag for package files."""
import ctypes as c
from ctypes import wintypes as w
from pathlib import Path
import json
import sys

dest=Path(sys.argv[1]).resolve(strict=True)
manifest=json.loads((dest/'DELIVERY_MANIFEST.json').read_text(encoding='utf-8'))
kernel=c.WinDLL('kernel32',use_last_error=True)
cloud=c.WinDLL('CldApi',use_last_error=True)
create=kernel.CreateFileW
create.argtypes=[w.LPCWSTR,w.DWORD,w.DWORD,c.c_void_p,w.DWORD,w.DWORD,w.HANDLE]
create.restype=w.HANDLE
close=kernel.CloseHandle;close.argtypes=[w.HANDLE];close.restype=w.BOOL
get=cloud.CfGetPlaceholderInfo
get.argtypes=[w.HANDLE,c.c_int,c.c_void_p,w.DWORD,c.POINTER(w.DWORD)]
get.restype=c.c_long

class StandardInfo(c.Structure):
    _fields_=[('on_disk',c.c_longlong),('validated',c.c_longlong),('modified',c.c_longlong),('properties',c.c_longlong),
              ('pin_state',c.c_int),('in_sync_state',c.c_int),('file_id',c.c_longlong),('sync_root_id',c.c_longlong),('identity_length',w.ULONG)]

def state(path):
    # Query only metadata; do not hydrate or modify the file.
    h=create(str(path),0x80,7,None,3,0x00200000,None)
    if h in (None,c.c_void_p(-1).value):return {'in_sync':False,'open_error':c.get_last_error()}
    try:
        buf=c.create_string_buffer(65536);length=w.DWORD()
        hr=get(h,1,buf,len(buf),c.byref(length))
        if hr:return {'in_sync':False,'query_hresult':f'0x{hr & 0xffffffff:08x}'}
        info=StandardInfo.from_buffer_copy(buf)
        return {'in_sync':info.in_sync_state==1 and info.modified==0,'modified_bytes':info.modified}
    finally:close(h)

files=[f['file'] for f in manifest['files']]+['DELIVERY_MANIFEST.json']
if (dest/'SYNC_STATUS.md').is_file():files.append('SYNC_STATUS.md')
states={name:state(dest/name) for name in files}
report=dict(total=len(states),in_sync=sum(s['in_sync'] for s in states.values()),not_in_sync={name:s for name,s in states.items() if not s['in_sync']})
print(json.dumps(report,indent=2))
raise SystemExit(0 if report['in_sync']==report['total'] else 1)
