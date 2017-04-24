program PMailAttachment;

uses
  System.StartUpCopy,
  FMX.Forms,
  MailAttachmentMain in 'MailAttachmentMain.pas' {ShareDemoForm},
  wwEmailWithAttachment in 'wwEmailWithAttachment.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TShareDemoForm, ShareDemoForm);
  Application.Run;
end.
