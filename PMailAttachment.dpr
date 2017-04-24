program PMailAttachment;

uses
  System.StartUpCopy,
  FMX.Forms,
  MailAttachmentMain in 'MailAttachmentMain.pas' {EmailAttachmentDemoForm},
  wwEmailWithAttachment in 'wwEmailWithAttachment.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TEmailAttachmentDemoForm, EmailAttachmentDemoForm);
  Application.Run;
end.
