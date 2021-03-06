unit MailAttachmentMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ScrollBox, FMX.Memo,
  FMX.Memo.Types;

type
  TEmailAttachmentDemoForm = class(TForm)
    Button2: TButton;
    Memo1: TMemo;
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  EmailAttachmentDemoForm: TEmailAttachmentDemoForm;

implementation

{$R *.fmx}

uses System.IOUtils, wwEmailWithAttachment;

procedure TEmailAttachmentDemoForm.Button2Click(Sender: TObject);
var
  fileName: string;
  lines: TStringList;
begin
  fileName := System.IOUtils.TPath.GetDocumentsPath() +
    TPath.DirectorySeparatorChar + 'MyAttachment.txt';

  // Create file that we will attach later
  lines := TStringList.Create;
  try
    lines.Add('first line of file');
    lines.Add('second line of file');
    lines.SaveToFile(fileName);
  finally
    lines.Free;
  end;

  wwEmail(
    ['Roy Woll<roywoll@gmail.com>', 'royswoll@yahoo.com'],
    ['nancywoll@gmail.com'], [], 'Example of Email with Attachment',
      'Notice that there is an attached file with this email.', fileName);
end;

end.
