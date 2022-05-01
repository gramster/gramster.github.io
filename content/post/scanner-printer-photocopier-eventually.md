---
title: Scanner + Printer == Photocopier (eventually)
date: 2008-02-01T05:35:00
author: Graham Wheeler
category: Programming
slug: scanner-printer-photocopier-eventually
---

My wife has been bugging me to make it easier for her to use our scanner
and printer to make copies. I could buy a cheap all-in-one but she
actually needs laser copies, not inkjet, for her hobby of stamp carving
(she can iron a laser-printed image to make a basic transfer). The
scanner and printer are attached to my PC but she wants to make copies
without having to log on to my PC or bother me.

I believe that HP scanners can do this, but I have an Epson Perfection
4490, and if you press the 'Scan to Printer' button on the front it pops
up UI on the PC. It's definitely not a one-step process and the buttons
are a bit of a joke. So I thought I'd write my own app using Window
Image Acquisition to do this. My original plan was to write something
that hooked the button event and then slept in the notification tray,
waking up when the button gets pressed.
<!-- TEASER_END -->

Of course, things are never that easy. I wrote the initial code, but the
events never came to me (I've since discovered that the Epson sends a
**wiaEventScanImage2** event instead of a wiaEventScanPrintImage event,
so its possible that was the problem and I may revisit my original code
at some point). Whenever I pressed the button Epson's UI would pop up.
Even more annoying, the first UI was a choice dialog asking me to choose
between Epson Creativity Suite and Epson Scan, even though I had
explicitly configured the scanner software to always use the copy
utility in the creativity suite.

I started mucking about with registry settings but that quickly started
getting ugly and wasn't really helping. So I hacked it. The first thing
I did was to uninstall all the Epson Creativity Suite software, which
was pretty useless anyway. That got rid of the choice dialog so pressing
the button launched Epson Scan. Then I looked at the process that was
running and found it was C:\\Windows\\twain\_32\\escndv\\escndv.exe
(which itself was confusing as the same app is also installed in
c:\\Program Files\\Epson). I renamed that app escndv-orig.exe. I then
made my own app in that directory and named it escndv.exe - so now
pressing the button launched my app at last.

Next I had to write the code to scan and print with no UI. That proved a
bit odd too, but eventually I figured it out. The code is shown below.
It's really rough, but it works. I built it as a C\# Windows console
project, adding references to the WIA COM DLL and System.Drawing and
System.Drawing.Printing. The app will pop open a dialog on first run to
ask what scanner to use (even if there is only one); after that the
scanner ID is persisted in the app settings. It prints to the default
printer.

This is not completely UI-less - it does pop up a console window briefly
while the scan is in progress - but at least no interaction on the PC is
required.

I plan to extend this later to have one button do an autocrop and scale
to fit. Currently pressing any of the other buttons will launch the
original Epson Scan software.

```c#
using System;
using System.Collections.Generic;
using System.Text;
using PrintScan.Properties;
using System.Drawing;
using System.Drawing.Printing;
using System.IO;
using WIA;

namespace PrintScan
{
    class Program
    {
        static void Main(string[] args)
        {
            new Program().Run(args);
        }

        Settings settings = new Settings();

        void Configure() // Get the scanner to use via Choose Scanner dialog
        {
            CommonDialogClass class1 = new CommonDialogClass();
            Device d = class1.ShowSelectDevice(WiaDeviceType.ScannerDeviceType, true, false);
            if (d != null)
            {
                settings.DeviceID = d.DeviceID;
                settings.Save();
            }
        }

        bool RunProcess(string cmd, string args) // Run some other exe; used to fall back to Epson Scan
        {
            System.Diagnostics.Process proc = new System.Diagnostics.Process();
            proc.StartInfo.FileName = cmd;
            proc.StartInfo.Arguments = args;
            proc.StartInfo.UseShellExecute = false;
            return proc.Start();
        }

        const string tempFile = @"c:\\temp\\page.bmp";

        void Run(string[] args)
        {
            if (settings.DeviceID == null || settings.DeviceID.Length == 0)
                Configure();

            DeviceManager manager = new DeviceManagerClass();
            Device d = null;

            if (args[1] == ("/StiEvent:"+EventID.wiaEventScanImage2)) // I'm surprised it's not EventID.wiaEventScanPrintImage
            {
                // Find our scanner
                foreach (DeviceInfo info in manager.DeviceInfos)
                {
                    if (info.DeviceID == settings.DeviceID)
                    {
                        d = info.Connect();

                        // Do the scan and save it to a temp file

                        ImageFile page = d.Items[1].Transfer(d.Items[1].Formats[1]) as ImageFile;

                        if (File.Exists(tempFile))
                            File.Delete(tempFile);

                        page.SaveFile(tempFile);

                        // print it to the default printer

                        PrintDocument pd = new PrintDocument();
                        pd.PrintPage += new PrintPageEventHandler(pd_PrintPage);
                        pd.Print();
                        break;
                    }
                }
            }
            else
            {
                RunProcess(@"C:\\Windows\\twain\_32\\escndv\\escndv-orig.exe", args[0]+" "+args[1]);
            }
        }

        void pd_PrintPage(object sender, PrintPageEventArgs e)
        {
            Bitmap bmp = new Bitmap(tempFile);
            GraphicsUnit gu = GraphicsUnit.Document;
            RectangleF bounds = bmp.GetBounds(ref gu);
            e.Graphics.DrawImage(bmp, bounds, bounds, gu);
        }
    }
}
```
