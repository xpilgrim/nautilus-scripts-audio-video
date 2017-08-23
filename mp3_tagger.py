#!/usr/bin/env python
# -*- coding: utf-8 -*-
# pylint: disable-msg=C0103

"""

Autor: Joerg Sorge

Distributed under the terms of GNU GPL version 2 or later
Copyright (C) Joerg Sorge joergsorge at ggooogl
2017-07-18

This script is a so called "nautilus script".

This script writes TD3-TAgs in mp3 files

Depends on:
    Python, Tkinter, python-mutagen
Install additional packages with:
    sudo apt-get install python-tk python-mutagen
"""

import os
import sys
import subprocess
from ScrolledText import ScrolledText
import string

try:
    from Tkinter import Label, Entry, Button, Frame, END
    import tkMessageBox
except ImportError:
    print "ImportError Tkinter"
    try:
        message = ("ImportError Tkinter!\nPlease install it with:\n"
                + "sudo apt-get install python-tk")
        subprocess.Popen(["zenity", "--info", "--text", message],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
    except Exception, e:
        print e
    sys.exit()

try:
    import mutagen
    from mutagen.id3 import ID3, TPE1, TIT2
    from mutagen.id3 import ID3NoHeaderError
except ImportError:
    print "ImportError mutagen"
    try:
        message = ("ImportError mutagen!\nPlease install it with:\n"
                + "sudo apt-get install python-mutagen")
        subprocess.Popen(["zenity", "--info", "--text", message],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
    except Exception, e:
        print e
    sys.exit()


class app_config(object):
    """Application-Config"""
    def __init__(self):
        """Settings"""
        # app_config
        self.app_desc = u"mp3 Tagger"
        # for normal usage set to no!!!!!!
        self.app_windows = "no"
        self.app_errorfile = "error_mp3_tagger.log"


def switch_lang(self):
    """switch lang for msgs"""
    self.msg = ["lang"]
    self.err = ["lang"]
    if os.getenv('LANG')[0:2] == "de":
        self.msg.append("Simpler ID3-Tagger...")  # 1
        self.msg.append("\nArbeitsverzeichnis:")  # 2
        self.msg.append("\nDateien ausgewaehlt:")
        self.msg.append("\nAchtung!"
            + "\nNur Interpret und Titel werden bearbeitet, "
            + "alles andere wird gleoescht!")  # 4
        self.msg.append("ID3-Tags schreiben")
        self.msg.append("ID3-Tags in Datei schreiben?")  # 6
        self.msg.append("\nID3-Tags in Datei schreiben...")
        self.msg.append("\nAbgebrochen...")  # 8
        self.msg.append("\nMax. Anzahl Dateien ueberschritten!")  # 9

        self.err.append("Fehlendes Paket ")
        self.err.append(" Bitte installieren durch\n sudo apt-get install ")
        self.err.append("Dies ist ein Nautilus Script, "
            + "zum Bearbeiten muessen Dateien ausgewaehlt sein.")  # 2
        self.err.append("Keine mp3 Dateien gefunden...")  # 3
        self.err.append("Kein ID3V2 Tag vorhanden in: ")
    else:
        self.msg.append("Simple ID3 Tagger...\n")  # 1
        self.msg.append("\nDirectory to work in:")  # 2
        self.msg.append("\nFiles to work on:")
        self.msg.append("\nAttention!"
            + "Only Interpret and Title are edited. "
            + "All other will be deleted!")  # 4
        self.msg.append("Write Tags")
        self.msg.append("Writing ID3-Tags, Are You Sure?")  # 6
        self.msg.append("\nWriting ID3-Tags...")
        self.msg.append("\nCanceled...")  # 8
        self.msg.append("\nMax number of files reached...")  # 8

        self.err.append("Missing package ")  # 1
        self.err.append("!\nPlease install it with:\n sudo apt-get install ")
        self.err.append("This is a nautilus script "
            + "that need one or more selected files for working on")
        self.err.append("No mp3 files found...")  # 3
        self.err.append("No ID3V2 tag present in: ")


def check_packages(self, package_list):
    """check_packages"""
    try:
        for package in package_list:
            print package
            p = subprocess.Popen(["dpkg-query", "-s", package,
                "2>/dev/null|grep"],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
            #print p
            #print string.find(p[0], "installed")
            if string.find(p[0], "installed") == -1:
                message = (self.err[1] + package + self.err[2] + package)
                self.display_logging(message, "r")
                return None
    except Exception, e:
        self.display_logging("Error: %s" % str(e), "r")
        return None
    return True


def extract_filename(path_filename):
    """extract filename right from slash"""
    if ac.app_windows == "no":
        filename = path_filename[string.rfind(path_filename, "/") + 1:]
    else:
        filename = path_filename[string.rfind(path_filename, "\\") + 1:]
    return filename


def read_id3_tags(self, mp3_file):
    """read_id3_tag"""
    author = None
    title = None
    #self.display_logging("Save tags...")
    try:
        mp3_meta = ID3(mp3_file)
        tags = mp3_meta.pprint().splitlines()

        for tag in tags:
            #print tag
            if tag[:4] == "TPE1":
                author = tag[5:]
                #print author
            if tag[:4] == "TIT2":
                title = tag[5:]
                #print title

    except ID3NoHeaderError:
        self.display_logging(self.err[5]
            + extract_filename(mp3_file), None)
        author = "no author"
        title = "no title"
    return author, title


def write_id3_tags(self, mp3_file, author, title):
    """read_id3_tag"""
    if author is None and title is None:
        # add empty tags
        author = "unknown author"
        title = "unknown title"

    #self.display_logging("Write tags...")
    try:
        mp3_meta = ID3(mp3_file)
        mp3_meta.delete()
        mp3_meta.add(TPE1(encoding=3, text=author))
        mp3_meta.add(TIT2(encoding=3, text=title))
        mp3_meta.save()
    except ID3NoHeaderError:
        self.display_logging("No tag present...", None)
        try:
            mp3_meta = mutagen.File(mp3_file, easy=True)
            mp3_meta.add_tags()
            mp3_meta.save()

            try:
                mp3_meta = ID3(mp3_file)
                mp3_meta.add(TPE1(encoding=3, text=author))
                mp3_meta.add(TIT2(encoding=3, text=title))
                mp3_meta.save()
            except Exception, e:
                self.display_logging("%s" % str(e), None)
        except Exception, e:
            self.display_logging("Error: %s" % str(e), "r")


class my_form(Frame):
    """Form"""
    def __init__(self, master=None):
        """create elements of form"""
        Frame.__init__(self, master)
        self.pack()

        self.textBox = ScrolledText(self, height=5, width=115)
        #self.textBox.pack()
        self.textBox.tag_config("b", foreground="blue")
        self.textBox.tag_config("r", foreground="red")

        self.label_dummy = Label(self, width=100, text=" ")
        self.label_dummy.pack()

        self.label_dummy1 = Label(self, width=100, text=" ")
        self.pressButton = Button(self,
                text="Write ID3 Tags", command=self.write_id3_tags_prepare)
        #self.pressButton.pack()

        # registering callback
        self.listenID = self.after(400, self.lets_rock)

    def display_logging(self, log_message, text_format):
        """display messages in form, loading periodically """
        if text_format is None:
            self.textBox.insert(END, log_message + "\n")
        else:
            self.textBox.insert(END, log_message + "\n", text_format)

    def write_id3_tags_prepare(self):
        """prepare for writing tags"""
        result = tkMessageBox.askquestion(
                        self.msg[5], self.msg[6], icon='warning')
        if result == 'yes':
            self.display_logging(self.msg[7], None)
            z = 0
            for item in self.mp3_files:
                self.display_logging(self.entry_a[z].get(), "b")
                self.display_logging(self.entry_b[z].get(), "b")
                write_id3_tags(self, item,
                    self.entry_a[z].get(), self.entry_b[z].get())
                self.textBox.see(END)
                z += 1
        else:
            self.display_logging(self.msg[8], None)
            self.textBox.see(END)

    def lets_rock(self):
        """man funktion"""
        print "lets rock"
        switch_lang(self)
        self.display_logging(self.msg[1], None)

        # check packages
        check_package = True
        check_package = check_packages(self,
                                ["sox", "mp3gain", "mp3splt", "easytag"])
        if check_package is None:
            return

        try:
            path_files = (
                os.environ['NAUTILUS_SCRIPT_SELECTED_FILE_PATHS'].splitlines())
        except Exception, e:
            self.display_logging("Error: %s" % str(e), "r")
            self.display_logging(self.err[2], None)
            return

        self.display_logging(self.msg[2], None)
        self.display_logging(os.path.dirname(path_files[0]), None)
        self.display_logging(self.msg[3], None)
        self.mp3_files = []
        for item in path_files:
            if string.rfind(item, ".mp3") == -1:
                # no mp3:
                continue
            self.mp3_files.append(item)
            self.display_logging(extract_filename(item), "b")

        # check for mp3 files
        if len(self.mp3_files) == 0:
            self.display_logging(self.err[3], "r")
            self.display_logging(self.msg[4], None)
            return
        #return
        z = 0
        self.label_dummy = []
        self.label = []
        self.entry_a = []
        self.entry_b = []
        for item in self.mp3_files:
            if z == 10:
                self.display_logging(self.msg[9], "b")
                continue
            #self.display_logging(extract_filename(item), "r")
            author, title = read_id3_tags(self, item)
            try:
                self.my_label = Label(self,
                    width=100, text=extract_filename(item))
                self.label.append(self.my_label)
                self.label[z].pack()

                self.my_entry_a = Entry(self, width=100)
                self.entry_a.append(self.my_entry_a)
                self.entry_a[z].pack()
                self.entry_a[z].insert(0, author)

                self.my_entry_b = Entry(self, width=100)
                self.entry_b.append(self.my_entry_b)
                self.entry_b[z].pack()
                self.entry_b[z].insert(0, title)

                self.my_label_dummy = Label(self, width=100, text=" ")
                self.label_dummy.append(self.my_label_dummy)
                self.label_dummy[z].pack()
                z += 1
            except Exception, e:
                self.display_logging("Error: %s" % str(e), "r")

        self.display_logging(self.msg[4], "r")
        # pack some widgets on bottom
        self.textBox.pack()
        self.textBox.see(END)
        self.label_dummy1.pack()
        self.pressButton.pack()


if __name__ == "__main__":
    print "mp3 tagger started"
    ac = app_config()
    mything = my_form()
    mything.master.title("Simple mp3 Tagger")
    mything.mainloop()
    print "lets_lay_down"
    sys.exit()
