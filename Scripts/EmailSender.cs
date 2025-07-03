using System.IO;
using System.Net;
using System.Net.Mail;
using Godot;

public class EmailSender
{
    public static void SendWav(string globalWavPath)
    {
        string from = "youbeatai@gmail.com";
        string pass = "plkqkbpemvqierqw";
        
        string to = ReadEmailAdress();
        string subject = "Hier is je liedje!";
        string body = "Het liedje is als bestand bijgevoegt";

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

    private static string ReadEmailAdress()
    {
        string path = Path.Combine(ProjectSettings.GlobalizePath("user://"), "email_adress.txt");
        string email = File.ReadAllText(path);
        return email;
    }
}