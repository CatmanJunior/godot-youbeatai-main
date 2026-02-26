using System.IO;
using System.Net;
using System.Net.Mail;
using Godot;

[GlobalClass]
public partial class Mailer: Node
{
    public override void _Ready()
    {
        base._Ready();
    }

    public static string GetDocumentspath()
    {
        string path = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.MyDocuments), "Rimte Robot");
        if( Path.Exists(path) == false )
            Directory.CreateDirectory(path);
            
        return path;
    }

    public static void SendWav(string globalWavPath, string to)
    {
        string from = "youbeatai@gmail.com";
        string pass = "plkqkbpemvqierqw";
        
        string subject = "Hier is je liedje!";
        string body = "Het liedje is als bestand bijgevoegd";

        var message = new MailMessage(from, to, subject, body);
        var attachment = new Attachment(globalWavPath);
        message.Attachments.Add(attachment);

        var smtpClient = new SmtpClient("smtp.gmail.com", 587)
        {
            EnableSsl = true,
            Credentials = new NetworkCredential(from, pass)
        };

        smtpClient.Send(message);
    }
}