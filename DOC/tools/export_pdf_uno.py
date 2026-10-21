"""Fallback PDF export with refreshed indexes; run using LibreOffice's Python.
Keeps the Word document intact. Word and Writer paginate independently.
"""
from pathlib import Path
import subprocess, sys, time, socket
import uno
from com.sun.star.beans import PropertyValue

root=Path(__file__).resolve().parents[2]
program=Path(sys.executable).parent
profile=root/'SRC/test-results/lo-export-profile'
with socket.socket() as sock:
    sock.bind(('127.0.0.1',0)); port=sock.getsockname()[1]
proc=subprocess.Popen([str(program/'soffice.exe'),'--headless','--norestore',
    '-env:UserInstallation='+profile.as_uri(),
    f'--accept=socket,host=127.0.0.1,port={port};urp;StarOffice.ComponentContext'],
    creationflags=subprocess.CREATE_NO_WINDOW)
def prop(name,value):
    p=PropertyValue(); p.Name=name; p.Value=value; return p
local=uno.getComponentContext()
resolver=local.ServiceManager.createInstanceWithContext('com.sun.star.bridge.UnoUrlResolver',local)
doc=None; desktop=None
try:
    for _ in range(120):
        try:
            ctx=resolver.resolve(f'uno:socket,host=127.0.0.1,port={port};urp;StarOffice.ComponentContext'); break
        except Exception: time.sleep(.5)
    else: raise RuntimeError('LibreOffice listener not ready')
    desktop=ctx.ServiceManager.createInstanceWithContext('com.sun.star.frame.Desktop',ctx)
    doc=desktop.loadComponentFromURL((root/'DOC/Nhom08_BaoCao_HQTCSDL_HomeFix.docx').as_uri(),'_blank',0,
        (prop('Hidden',True),prop('ReadOnly',True),prop('UpdateDocMode',3)))
    for _ in range(2):
        doc.refresh()
        indexes=doc.getDocumentIndexes()
        for i in range(indexes.Count): indexes.getByIndex(i).update()
        doc.getTextFields().refresh()
    doc.storeToURL((root/'DOC/Nhom08_BaoCao_HQTCSDL_HomeFix.pdf').as_uri(),
        (prop('FilterName','writer_pdf_Export'),prop('Overwrite',True),
         prop('FilterData',(prop('ExportBookmarks',True),prop('UseTaggedPDF',True)))))
    print('PDF exported with updated contents and caption lists',flush=True)
finally:
    if doc is not None: doc.close(True)
    if desktop is not None: desktop.terminate()
    try: proc.wait(timeout=10)
    except subprocess.TimeoutExpired: proc.terminate()
