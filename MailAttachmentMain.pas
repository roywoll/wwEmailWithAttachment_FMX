unit MailAttachmentMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ScrollBox, FMX.Memo;

type
  TShareDemoForm = class(TForm)
    Button2: TButton;
    Memo1: TMemo;
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ShareDemoForm: TShareDemoForm;

implementation

{$R *.fmx}

uses System.IOUtils, wwEmailWithAttachment;

procedure TShareDemoForm.Button2Click(Sender: TObject);
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
  wwEmail(['roywoll@gmail.com', 'royswoll@yahoo.com'],
    [], [], 'Subject', 'Content', fileName);
end;

end.
