This project uses the following method defined in iosEmailWithAttachment.pas

procedure wwEmail(
   Recipients: Array of String;
   ccRecipients: Array of String;
   bccRecipients: Array of String;
   Subject, Content,
   AttachmentPath: string;
   mimeTypeStr: string = '');

Add this unit to your form's uses clause, and then you can send an email using the following
syntax.

  wwEmail(['roywoll@gmail.com', 'royswoll@yahoo.com'],
    [], [], 'Subject', 'Content', fileName);

Note: In order for this routine to compile and link, you will need to add
the MessageUI framework to your ios sdk in the RAD Studio IDE.
The steps are simple, but as follows.
1. Select from the IDE - Tools | Options | SDK Manager

2. Then for your 64 bit platform (and 32 bit if you like) do the following
   a) Scroll to the bottom of your Frameworks list and select the last one
   b) Click the add button on the right to add a new library refence and
      then enter the following data for your entry
      
      Path on remote machine:
        $(SDKROOT)/System/Library/Frameworks

      File Mask
        MessageUI

      Path Type
       Leave unselected
  
3. Click the button Update Local File Cache to update your sdk

4. Click the OK Button to close the dialog

Now when you compile it should not yield a link error