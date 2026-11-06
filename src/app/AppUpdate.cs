using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;

namespace MustekStudio
{
    internal sealed class AppUpdate
    {
        const string Repository = "https://raw.githubusercontent.com/5U5L1K/Mustek-1200-UB-Plus-Win10-11/";
        const int MaximumInstallerBytes = 64 * 1024 * 1024;
        public Version Version { get; private set; }
        string checksum;

        static HttpWebResponse Open(string url)
        {
            ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;
            HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);
            request.AllowAutoRedirect = false;
            request.Timeout = 15000;
            request.ReadWriteTimeout = 15000;
            request.UserAgent = "Mustek-Studio";
            HttpWebResponse response = (HttpWebResponse)request.GetResponse();
            if (response.StatusCode == HttpStatusCode.OK) return response;
            response.Dispose();
            throw new IOException("Unexpected update server response.");
        }

        public static AppUpdate Check()
        {
            string[] lines;
            using (HttpWebResponse response = Open(Repository + "main/update.txt"))
            using (StreamReader reader = new StreamReader(response.GetResponseStream(), Encoding.ASCII))
            {
                char[] buffer = new char[256];
                int count = reader.ReadBlock(buffer, 0, buffer.Length);
                if (count == buffer.Length) throw new IOException("Invalid update metadata.");
                lines = new string(buffer, 0, count).Trim().Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
            }
            Version latest;
            if (lines.Length != 2 || !Regex.IsMatch(lines[0], @"\A[0-9]+\.[0-9]+\.[0-9]+\z") ||
                !Version.TryParse(lines[0], out latest) || !Regex.IsMatch(lines[1], @"\A[0-9a-fA-F]{64}\z"))
                throw new IOException("Invalid update metadata.");
            Version current = Assembly.GetExecutingAssembly().GetName().Version;
            if (latest <= new Version(current.Major, current.Minor, current.Build)) return null;
            return new AppUpdate { Version = latest, checksum = lines[1].ToLowerInvariant() };
        }

        public string Download(string dataRoot)
        {
            string directory = Path.Combine(dataRoot, "updates");
            Directory.CreateDirectory(directory);
            if ((File.GetAttributes(directory) & FileAttributes.ReparsePoint) != 0)
                throw new IOException("Invalid update directory.");
            string installer = Path.Combine(directory, "setup-" + Guid.NewGuid().ToString("N") + ".exe");
            try
            {
                using (HttpWebResponse response = Open(Repository + "refs/tags/v" + Version + "/MustekStudio-Setup.exe"))
                using (Stream input = response.GetResponseStream())
                using (FileStream output = new FileStream(installer, FileMode.CreateNew, FileAccess.Write))
                {
                    byte[] buffer = new byte[65536];
                    int total = 0, read;
                    while ((read = input.Read(buffer, 0, buffer.Length)) != 0)
                    {
                        total += read;
                        if (total > MaximumInstallerBytes) throw new IOException("The update exceeds the download size limit.");
                        output.Write(buffer, 0, read);
                    }
                }
                if (RuntimePackage.HashFile(installer) != checksum) throw new IOException("The installer checksum does not match.");
                return installer;
            }
            catch { DeleteDownload(installer); throw; }
        }

        public static void Install(string installer, string mutexName, string language)
        {
            string args = "/SILENT /SP- /NORESTART /UPDATE=1 /LANG=" + (language == "en" ? "en" : "ru") +
                " /DIR=" + ScannerEngine.Quote(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location)) +
                " /WAITMUTEX=" + ScannerEngine.Quote(mutexName);
            using (Process process = Process.Start(new ProcessStartInfo(installer, args) { UseShellExecute = false }))
                if (process == null) throw new IOException("Could not start Setup.");
        }

        static bool DeleteDownload(string path)
        {
            try { File.Delete(path); return true; }
            catch (IOException) { return false; }
            catch (UnauthorizedAccessException) { return false; }
        }

        public static void ClearPreviousDownloads(string dataRoot)
        {
            string directory = Path.Combine(dataRoot, "updates");
            try
            {
                if (!Directory.Exists(directory) || (File.GetAttributes(directory) & FileAttributes.ReparsePoint) != 0) return;
                foreach (string path in Directory.GetFiles(directory, "setup-*.exe"))
                {
                    if (!Regex.IsMatch(Path.GetFileName(path), @"\Asetup-[0-9a-f]{32}\.exe\z")) continue;
                    for (int i = 0; i < 10 && !DeleteDownload(path); i++) Thread.Sleep(500);
                }
            }
            catch (IOException) { }
            catch (UnauthorizedAccessException) { }
        }
    }
}
