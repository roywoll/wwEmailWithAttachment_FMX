program PMailAttachment;

uses
  System.StartUpCopy,
  FMX.Forms,
  MailAttachmentMain in 'MailAttachmentMain.pas' {EmailAttachmentDemoForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TEmailAttachmentDemoForm, EmailAttachmentDemoForm);
  Application.Run;
end.
