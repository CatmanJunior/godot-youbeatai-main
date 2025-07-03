using System.Net;
using System.Net.Mail;

public class EmailSender
{
    public static void SendWav(string globalWavPath)
    {
        string from = "youbeatai@gmail.com";
        string pass = "plkqkbpemvqierqw";
        
        string to = "youbeatai@gmail.com";
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
}