$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class HFHelpCapture {
 public delegate bool CB(IntPtr h, IntPtr l);
 [DllImport("user32.dll")] public static extern bool EnumWindows(CB c,IntPtr l);
 [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h,CB c,IntPtr l);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h,StringBuilder b,int n);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern uint RegisterWindowMessage(string s);
 [DllImport("user32.dll")] public static extern IntPtr SendMessageTimeout(IntPtr h,uint m,IntPtr w,IntPtr l,uint flags,uint timeout,out IntPtr result);
 [DllImport("oleacc.dll")] public static extern int ObjectFromLresult(IntPtr result,ref Guid iid,IntPtr w,[MarshalAs(UnmanagedType.Interface)] out object obj);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h,out uint p);
 [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h,IntPtr dc,uint flags);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h,out RECT r);
 [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h,int x,int y,int w,int he,bool paint);
 [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h,uint msg,IntPtr w,IntPtr l);
 public struct RECT { public int Left,Top,Right,Bottom; }
 public static IntPtr Find(int pid){IntPtr found=IntPtr.Zero;EnumWindows((h,l)=>{uint p;GetWindowThreadProcessId(h,out p); RECT r; GetWindowRect(h,out r);if(p==pid && r.Right-r.Left>500)found=h;return true;},IntPtr.Zero);return found;}
 public static object Html(IntPtr h){IntPtr server=IntPtr.Zero;EnumChildWindows(h,(c,l)=>{StringBuilder b=new StringBuilder(256);GetClassName(c,b,256);if(b.ToString()=="Internet Explorer_Server")server=c;return true;},IntPtr.Zero);if(server==IntPtr.Zero)return null;IntPtr result;SendMessageTimeout(server,RegisterWindowMessage("WM_HTML_GETOBJECT"),IntPtr.Zero,IntPtr.Zero,2,3000,out result);Guid iid=new Guid("332C4425-26CB-11D0-B483-00C04FD90119");object doc;ObjectFromLresult(result,ref iid,IntPtr.Zero,out doc);return doc;}
}
'@
$helpProcess = Start-Process -FilePath "$env:WINDIR\hh.exe" -ArgumentList ('"' + (Join-Path $repo 'HELP/HomeFix_HuongDan.chm') + '"') -WindowStyle Hidden -PassThru
try {
    Start-Sleep -Seconds 3
    $handle=[HFHelpCapture]::Find($helpProcess.Id)
    if ($handle -eq [IntPtr]::Zero) { throw 'CHM window not found' }
    [HFHelpCapture]::MoveWindow($handle,20,20,1380,900,$true) | Out-Null
    Start-Sleep -Seconds 2
    $htmlDoc=[HFHelpCapture]::Html($handle)
    if ($null -eq $htmlDoc) { throw 'CHM HTML document not accessible' }
    $bodyText=$htmlDoc.body.innerText
    $audit=[ordered]@{title=$htmlDoc.title; text=$bodyText; scrollWidth=$htmlDoc.documentElement.scrollWidth; clientWidth=$htmlDoc.documentElement.clientWidth; charset=$htmlDoc.charset}
    $audit | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $repo 'DOC/evidence/report-revision/chm-native.json')
    Write-Output ('Native title: '+$htmlDoc.title)
    Write-Output ('Native dimensions: '+$htmlDoc.documentElement.scrollWidth+' / '+$htmlDoc.documentElement.clientWidth)
    $rect=New-Object HFHelpCapture+RECT
    [HFHelpCapture]::GetWindowRect($handle,[ref]$rect) | Out-Null
    $bitmap=New-Object System.Drawing.Bitmap(($rect.Right-$rect.Left),($rect.Bottom-$rect.Top))
    $graphics=[System.Drawing.Graphics]::FromImage($bitmap)
    $dc=$graphics.GetHdc()
    try { [HFHelpCapture]::PrintWindow($handle,$dc,2) | Out-Null } finally { $graphics.ReleaseHdc($dc) }
    $bitmap.Save((Join-Path $repo 'DOC/evidence/report-revision/chm-native.png'))
    $graphics.Dispose(); $bitmap.Dispose()
    Write-Output 'Captured native CHM window'
} finally {
    if ($handle -ne [IntPtr]::Zero) { [HFHelpCapture]::PostMessage($handle,0x0010,[IntPtr]::Zero,[IntPtr]::Zero) | Out-Null }
}
