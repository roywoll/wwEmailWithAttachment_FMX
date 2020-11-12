unit wwEmailWithAttachment;
{$define dynamicMessageUI}
//{$define SupportMapi}
{
  // Copyright (c) 2020 by Woll2Woll Software
  //
  // Methods: wwEmail (Email with attachment for ios, android, and windows)
  //
  // Modified Android to open writeable public directories in order to allow
  // email to open file.
  //
  // 4/8/18 - Consider adding back to library fmxinfopower since we are now
  // dynamically loading messageui so no more linker issues dlopen/dlclose
  //

  procedure wwEmail(
   Recipients: Array of String;
   ccRecipients: Array of String;
   bccRecipients: Array of String;
   Subject, Content,
   AttachmentPath: string;
   mimeTypeStr: string = '')

  In Windows, you can choose between mapi and ole via the Protocol property.
  The method defaults to using ole
  for sending the email.  Ole will only send attachments with Microsoft Outlook,
  but it also supports cc and bcc addresses.

  ANDROID ADDITIONAL STEPS

  When building with more recent Android SDK versions you will need to give your application the ability to update URI paths. The steps are the following.

  1. Edit your project AndroidManifest.template.xml file (located in your main project directory) and insert the following text:

  <provider
  android:name="android.support.v4.content.FileProvider"
  android:authorities="%package%.fileprovider"
  android:exported="false"
  android:grantUriPermissions="true">
  <meta-data
  android:name="android.support.FILE_PROVIDER_PATHS"
  android:resource="@xml/file_provider_paths" />
  </provider>

  2. Create the following file named file_provider_paths.xml and put it in your project's main directory

  <?xml version="1.0" encoding="utf-8"?>
  <paths xmlns:android="http://schemas.android.com/apk/res/android">
  <external-path name="external_files" path="."/>
  </paths>

  3. Within the Delphi IDE, add the file_provider_paths.xml to your deployment for Android

  After adding the file, edit the Remote Path location so that it contains the value res\xml\


  Please refer to our demo project PMailAttachment for a complete example of this as it has implemented all the above steps.


  IOS NOTES
  If you leave the dynamicMessageUI defined at the top of this unit
  the app will load the library during program execution and you will not have
  linkage issues. If you need to link statically for some reason, then
  you need to remove the define of dynamicmMessageUI, and perform the
  following steps so Delphi knows about the MessageUI framework at compile/link
  times. See below

  //
  // In order for this routine to compile and link statically for iOS, you will
  // need to add the MessageUI framework to your ios sdk
  // The steps are simple, but as follows.
  //
  // 1. Select from the IDE - Tools | Options | SDK Manager
  //
  // 2. Then for your 64 bit platform (and 32 bit if you like) do the following
  //    a) Scroll to the bottom of your Frameworks list and select the last one
  //
  //    b) Click the add button on the right to add a new library refence and
  //       then enter the following data for your entry
  //       Path on remote machine:
  //          $(SDKROOT)/System/Library/Frameworks
  //       File Mask
  //          MessageUI
  //       Path Type
  //          Leave unselected
  //
  // 3. Click the button Update Local File Cache to update your sdk
  //
  // 4. Click the OK Button to close the dialog
  //
  // Now when you compile it should not yield a link error

  Further notes on dynamic linking of MessageUI - We are not sure if ios App
  store would reject system framework such as messageui being loaded dynamically
  The are unclear on this.

//

}

{$if Defined(Android) or Defined(ios)}
{$define wwMobile}
{$endif}

interface
{$ObjExportAll On}
{$SCOPEDENUMS ON}
uses
  System.SysUtils, System.Classes, System.Types, System.Math, System.Generics.Collections,
  System.IOUtils, System.StrUtils,
  FMX.Consts,
  System.TypInfo,
  {$ifdef mswindows}
  System.Win.Comobj,
  Winapi.ShellAPI,
  Winapi.Windows,
  Winapi.ActiveX,
  System.Win.registry,
  {$endif}

  {$ifdef macos}
  Macapi.ObjectiveC, Macapi.Helpers,
  Macapi.ObjCRuntime,
  {$ifdef ios}
  iOSapi.AssetsLibrary,
  iOSapi.CocoaTypes, iOSapi.Helpers,
  FMX.Helpers.iOS, iOSapi.MediaPlayer, iOSapi.Foundation, iOSapi.UIKit, iOSapi.CoreGraphics,
  {$else}
  macAPI.CocoaTypes,
  {$endif}
  {$endif}
  FMX.Types,
  FMX.MediaLibrary, FMX.Controls,
  FMX.Platform, FMX.Graphics;

type
  TwwMailProtocol = (Mapi, Ole);

  TwwEmailAttachmentLocation = (Default, Cache, Files, ExternalDrive, ExternalCache);

procedure wwEmail(
   const Recipients: Array of String;
   const ccRecipients: Array of String;
   const bccRecipients: Array of String;
   Subject, Content,
   AttachmentPath: string;
   mimeTypeStr: string = ''); //; Protocol: TwwMailProtocol=TwwMailProtocol.Ole);

implementation


{$region 'ios'}

{$ifdef ios}
{$IF not defined(CPUARM)}
uses
     Posix.Dlfcn;
{$ENDIF}

const
  libMessageUI = '/System/Library/Frameworks/MessageUI.framework/MessageUI';
//  libMessageUI = '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/MessageUI.framework/MessageUI';
//  libMessageUI = '/Users/Shared/sdk/MessageUI.framework/MessageUI';

type
  MFMessageComposeResult = NSInteger;
  MFMailComposeResult = NSInteger;
  MFMailComposeViewControllerDelegate = interface;

  MFMailComposeViewControllerClass = interface(UINavigationControllerClass)
    ['{B6292F63-0DE9-4FE7-BEF7-871D5FE75362}']
    function canSendMail: Boolean; cdecl;
  end;

  MFMailComposeViewController = interface(UINavigationController)
    ['{5AD35A29-4418-48D3-AB8A-2F114B4B0EDC}']
    function mailComposeDelegate: MFMailComposeViewControllerDelegate; cdecl;
    procedure setMailComposeDelegate(mailComposeDelegate
      : MFMailComposeViewControllerDelegate); cdecl;
    procedure setSubject(subject: NSString); cdecl;
    procedure setToRecipients(toRecipients: NSArray); cdecl;
    procedure setCcRecipients(ccRecipients: NSArray); cdecl;
    procedure setBccRecipients(bccRecipients: NSArray); cdecl;
    procedure setMessageBody(body: NSString; isHTML: Boolean); cdecl;
    procedure addAttachmentData(attachment: NSData; mimeType: NSString;
      fileName: NSString); cdecl;
  end;

  TMFMailComposeViewController = class
    (TOCGenericImport<MFMailComposeViewControllerClass,
    MFMailComposeViewController>)
  end;

  MFMailComposeViewControllerDelegate = interface(IObjectiveC)
    ['{068352EB-9182-4581-86F5-EAFCE7304E32}']
    procedure mailComposeController(controller: MFMailComposeViewController;
      didFinishWithResult: MFMailComposeResult; error: NSError); cdecl;
  end;

  { ***************************************************************************************** }
  TMFMailComposeViewControllerDelegate = class(TOCLocal,
    MFMailComposeViewControllerDelegate)
  private
    MFMailComposeViewController: MFMailComposeViewController;
  public
    constructor Create(aMFMailComposeViewController
      : MFMailComposeViewController);
    procedure mailComposeController(controller: MFMailComposeViewController;
      didFinishWithResult: MFMailComposeResult; error: NSError); cdecl;
  end;


var
  mailComposeDelegate: TMFMailComposeViewControllerDelegate;

constructor TMFMailComposeViewControllerDelegate.Create
  (aMFMailComposeViewController: MFMailComposeViewController);
begin
  inherited Create;
  MFMailComposeViewController := aMFMailComposeViewController;
end;

// /Callback function when mail completes
procedure TMFMailComposeViewControllerDelegate.mailComposeController
  (controller: MFMailComposeViewController;
  didFinishWithResult: MFMailComposeResult; error: NSError);
var
  aWindow: UIWindow;
begin
  aWindow := TiOSHelper.SharedApplication.keyWindow;
  if Assigned(aWindow) and Assigned(aWindow.rootViewController) then
    aWindow.rootViewController.dismissModalViewControllerAnimated
      (True { animated } );
  MFMailComposeViewController.release;
  MFMailComposeViewController := nil;
end;

procedure wwEmail(
   const Recipients: Array of String;
   const ccRecipients: Array of String;
   const bccRecipients: Array of String;
   Subject, Content,
   AttachmentPath: string;
   mimeTypeStr: string = ''); //; Protocol: TwwMailProtocol=TwwMailProtocol.ole);
var
  MailController: MFMailComposeViewController;
  attachment: NSData;
  fileName: string;
  mimeType: NSString;
  //controller: UIViewController;
  Window: UIWindow;
  nsRecipients, nsccRecipients, nsbccRecipients: NSArray;

  function ConvertStringArrayToNSArray(InArray: Array of String): NSArray;
  var
    LRecipients: Array of Pointer;
    i: integer;
  begin
    SetLength(LRecipients, length(InArray));
    for i:= low(InArray) to high(InArray) do
       LRecipients[i]:= (StrToNSStr(InArray[i]) as ILocalObject).GetObjectID;
    Result := TNSArray.Wrap(TNSArray.OCClass.arrayWithObjects(
      @LRecipients[0], Length(LRecipients)));
  end;

begin
  fileName := AttachmentPath;

  MailController := TMFMailComposeViewController.Wrap
    (TMFMailComposeViewController.Alloc.init);
  mailComposeDelegate := TMFMailComposeViewControllerDelegate.Create(MailController);
  MailController.setMailComposeDelegate(mailComposeDelegate);
  MailController.setSubject(StrToNSStr(Subject));
  MailController.setMessageBody(StrToNSStr(Content), false);

  if (@Recipients<>nil) and (length(Recipients)>0) then
  begin
    nsRecipients:= ConvertStringArrayToNSArray(Recipients);
    MailController.setToRecipients(nsRecipients);
  end;

  if (@ccRecipients<>nil) and (length(ccRecipients)>0) then
  begin
    nsccRecipients:= ConvertStringArrayToNSArray(ccRecipients);
    MailController.setCcRecipients(nsccRecipients);
  end;

  if (@bccRecipients<>nil) and (length(bccRecipients)>0) then
  begin
    nsbccRecipients:= ConvertStringArrayToNSArray(bccRecipients);
    MailController.setBccRecipients(nsbccRecipients);
  end;

  if fileName <> '' then
  begin
    attachment := TNSData.Wrap(TNSData.Alloc.initWithContentsOfFile
      (StrToNSStr(fileName)));
    try
      if mimeTypeStr = '' then
        mimeTypeStr := 'text/plain';
      mimeType := StrToNSStr(mimeTypeStr);
      MailController.addAttachmentData(attachment, mimeType,
        StrToNSStr(TPath.GetFileName(fileName))); // shorten form
    finally
      attachment.release;
    end;
  end;

  Window := TiOSHelper.SharedApplication.keyWindow;
  if (Window <> nil) and (Window.rootViewController <> nil) then
    Window.rootViewController.presentModalViewController(MailController, True);
end;

//  3/17/18 - Defaults to using dynamic library of libmessageui instead of
// static so we don't have compile issues with deependency upon MessageUI framework
// which is no longer included in ios SDK after 10.3 - Not sure why though.
{$if not Defined(dynamicMessageUI) and Defined(CPUARM)}
 procedure LibMessageUIFakeLoader; cdecl; external libMessageUI;
{$else}
  {$IF defined(CPUARM)}
  const
    libdl       = '/usr/lib/libdl.dylib';
    RTLD_LAZY   = 1;             { Lazy function call binding.  }
  function dlclose(Handle: NativeUInt): Integer; cdecl;
    external libdl name _PU + 'dlclose';
  function dlopen(Filename: MarshaledAString; Flag: Integer): NativeUInt; cdecl;
    external libdl name _PU + 'dlopen';
  {$endif}
  var iMessageUIModule: THandle;

  initialization
    iMessageUIModule := dlopen(MarshaledAString(libMessageUI), RTLD_LAZY);

  finalization
    dlclose(iMessageUIModule);
  {$endif}
{$endif}
{$endregion}

{$region 'android'}
{$ifdef android}
uses
   Androidapi.JNI.GraphicsContentViewText,
   Androidapi.JNI.App,
   Androidapi.JNIBridge,
   Androidapi.JNI.JavaTypes,
   Androidapi.Helpers,
   Androidapi.JNI.Net,
   Androidapi.JNI.Os,
   Androidapi.IOUtils;

procedure wwEmail(
   const Recipients: Array of String;
   const ccRecipients: Array of String;
   const bccRecipients: Array of String;
   subject, Content, AttachmentPath: string;
   mimeTypeStr: string = ''); //; Protocol: TwwMailProtocol=TwwMailProtocol.ole);
var
  Intent: JIntent;
  Uri: Jnet_Uri;
  AttachmentFile: JFile;
  i: integer;
  emailAddresses: TJavaObjectArray<JString>;
  ccAddresses: TJavaObjectArray<JString>;
  fileNameTemp: JString;
  CacheName: string;
  IntentChooser: JIntent;
  ChooserCaption: string;
begin
  Intent := TJIntent.Create;
  Intent.setAction(TJIntent.JavaClass.ACTION_Send);
  Intent.setFlags(TJIntent.JavaClass.FLAG_ACTIVITY_NEW_TASK);

  emailAddresses := TJavaObjectArray<JString>.Create(length(Recipients));
  for i := Low(Recipients) to High(Recipients) do
    emailAddresses.Items[i] := StringToJString(Recipients[i]);

  ccAddresses := TJavaObjectArray<JString>.Create(length(ccRecipients));
  for i := Low(ccRecipients) to High(ccRecipients) do
    ccAddresses.Items[i] := StringToJString(ccRecipients[i]);

  Intent.putExtra(TJIntent.JavaClass.EXTRA_EMAIL, emailAddresses);
  Intent.putExtra(TJIntent.JavaClass.EXTRA_CC, ccAddresses);
  Intent.putExtra(TJIntent.JavaClass.EXTRA_SUBJECT, StringToJString(subject));
  Intent.putExtra(TJIntent.JavaClass.EXTRA_TEXT, StringToJString(Content));

  // Just filename portion for android services
  if AttachmentPath<>'' then
  begin
    CacheName := GetExternalCacheDir + TPath.DirectorySeparatorChar +
      TPath.GetFileName(AttachmentPath);
    if FileExists(CacheName) then
     Tfile.Delete(CacheName);
    Tfile.Copy(AttachmentPath, CacheName);

    fileNameTemp := StringToJString(CacheName);
    AttachmentFile := TJFile.JavaClass.init(fileNameTemp);

    if AttachmentFile <> nil then // attachment found
    begin
      AttachmentFile.setReadable(True, false);
      if not TOSVersion.Check(7) then
      begin
        Uri := TJnet_Uri.JavaClass.fromFile(AttachmentFile);
        Intent.putExtra(TJIntent.JavaClass.EXTRA_STREAM,
          TJParcelable.Wrap((Uri as ILocalObject).GetObjectID));
      end
      else begin  // support android 24  and later
        Intent.setFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
        Uri := TAndroidHelper.JFileToJURI(AttachmentFile);
        // 2/28/2020 - Missing this line before so attachment missing
        Intent.putExtra(TJIntent.JavaClass.EXTRA_STREAM,
          TJParcelable.Wrap((Uri as ILocalObject).GetObjectID));
      end;
//    Uri := FileProvider.getUriForFile(mReactContext,
//                mReactContext.getApplicationContext().getPackageName() + ".provider",
//                imageFile);
    end
  end;

  Intent.setType(StringToJString('vnd.android.cursor.dir/email'));

  ChooserCaption := 'Send To';
  IntentChooser := TJIntent.JavaClass.createChooser(Intent,
    StrToJCharSequence(ChooserCaption));
  TAndroidHelper.Activity.startActivityForResult(IntentChooser, 0);

end;
{$endif}
{$endregion}

{$region 'MSWindows'}
{$ifdef MSWINDOWS}

{$ifdef SupportMapi}
uses FMX.wwSendEmailMapi;
{$endif}

function Succeeded(Res: HResult): Boolean;
begin
  Result := Res and $80000000 = 0;
end;

// Want to Bypass exception so we check this without using the activex unit
function HaveActiveOleObject(const ClassName: string): boolean;
var
  ClassID: TCLSID;
  Unknown: IUnknown;
  oleresult: HResult;
begin
  ClassID := ProgIDToClassID(ClassName);
  oleResult:= GetActiveObject(ClassID, nil, Unknown);
  result:= Succeeded(oleResult);
end;

procedure DisplayMail(Address, ccAddress, bccAddress,
  Subject, Body: string; Attachment: TFileName);
var
  Outlook: OleVariant;
  Mail: Variant;
const
  olMailItem = $00000000;
begin
  if not HaveActiveOleObject('Outlook.Application') then
    Outlook := CreateOleObject('Outlook.Application')
  else
    Outlook:= GetActiveOleObject('Outlook.Application');
  Mail := Outlook.CreateItem(olMailItem);
  Mail.To := Address;
  Mail.BCC:= bccAddress;
  Mail.CC:= ccAddress;
  Mail.Subject := Subject;
  Mail.Body := Body;
  if Attachment <> '' then
    Mail.Attachments.Add(Attachment);
  Mail.Display;
end;

// Attachment seems to only work with Outlook
procedure wwEmail(
   const Recipients: Array of String;
   const ccRecipients: Array of String;
   const bccRecipients: Array of String;
   subject, Content, AttachmentPath: string;
   mimeTypeStr: string = ''); //; Protocol: TwwMailProtocol=TwwMailProtocol.ole);
var mailcommand: string;
  Recipient, ccRecipient, bccRecipient: string;
  LRecipient: string;
  {$ifdef supportmapi}
  sendmail: TwwSendMail;
  item: TRecipientItem;
  {$endif}
  ccaddress, bccaddress: string;
  pos1, pos2: integer;
  rawaddress, displayName: string;
  address: string;

  function GetAddress(const AAddresses: Array of String): string;
  var
    LAddress: string;
    Address: string;
  begin
    Address:= '';
    if @AAddresses <> nil then
    begin
      for LAddress in AAddresses do
      begin
        StringReplace(LAddress, ' ', '%20%', [rfReplaceAll, rfIgnoreCase]);
        if Address <> '' then
          Address := Address + ';' + LAddress
        else
          Address := LAddress;
      end;
    end;
    result:= Address;
  end;

begin

  {$ifdef supportmapi}
  if Protocol = TwwMailProtocol.mapi then
  begin
    // Later should do url encoding for recipients
    for LRecipient in Recipients do
    begin
      // StringReplace(LRecipient, ' ', '%20%', [rfReplaceAll, rfIgnoreCase]);
      if Recipient <> '' then
        Recipient := Recipient + ';' + LRecipient
      else
        Recipient := LRecipient;
    end;

    sendmail:= TwwSendMail.Create(nil);
    sendmail.Caption:= 'Caption';
    sendmail.Subject:= Subject;
    sendmail.Attachments.Add(AttachmentPath);
    sendmail.Text.Text:= Content;
    for address in Recipients do
    begin
      item:= TRecipientItem(sendmail.Recipients.Add);
      rawAddress:= address;
      if address.Contains('<') then
      begin
        pos1:= pos('<', address);
        pos2:= pos('>', address);
        rawAddress:= address.Substring(pos1, pos2-pos1-1)
      end;

      item.Address:= 'smtp:' + rawAddress;
      // Fax syntax: FAX:206-555-1212
      item.DisplayName:= address; //displayname;
    end;
    sendmail.ExecuteTarget(nil);
    sendmail.Free;
    exit;
  end;
  {$endif}

  Recipient:= GetAddress(Recipients);
  ccRecipient:= GetAddress(ccRecipients);
  bccRecipient:= GetAddress(bccRecipients);

  // If outlook is default mail client and we have attachment then use ole
  // otherwise just call open - ignore default mail client now since attach
  // only works with outlook for ole
  if (AttachmentPath<>'') then
  begin
    DisplayMail(Recipient, ccRecipient, bccRecipient, Subject, Content, AttachmentPath)
  end
  else begin
    mailcommand:= 'mailto:' + Recipient + '?Subject=' + Subject +
       '&Body=' + Content +
       '&Attachment=' + '"' + AttachmentPath + '"';

    ShellExecute(0, 'OPEN', pchar(mailcommand), nil,
      nil, sw_shownormal);
  end;

end;
{$endif}
{$endregion}

{$region 'osx'}
{$ifndef wwMobile}
{$ifdef macos}
procedure wwEmail(
   const Recipients: Array of String;
   const ccRecipients: Array of String;
   const bccRecipients: Array of String;
   subject, Content, AttachmentPath: string;
   mimeTypeStr: string = ''); //; Protocol: TwwMailProtocol=TwwMailProtocol.ole);
begin
 // Currently does nothing in osx
end;
{$endif}
{$endif}
{$endregion}

{$region 'linux64'}
{$ifdef linux}
procedure wwEmail(
   const Recipients: Array of String;
   const ccRecipients: Array of String;
   const bccRecipients: Array of String;
   subject, Content, AttachmentPath: string;
   mimeTypeStr: string = ''); //; Protocol: TwwMailProtocol=TwwMailProtocol.ole);
begin
 // Currently does nothing in linux
end;
{$endif}
{$endregion}

end.
