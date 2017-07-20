#!/usr/bin/env python
# -*- coding: utf-8 -*-
# pylint: disable-msg=C0103

"""

Autor: Joerg Sorge

Distributed under the terms of GNU GPL version 2 or later
Copyright (C) Joerg Sorge joergsorge at ggooogl
2011-09-26

"""

from Tkinter import Frame, END
from ScrolledText import ScrolledText
import os
import shutil
import sys
import subprocess
import string
import re
import datetime


class app_config(object):
    """Application-Config"""
    def __init__(self):
        """Settings"""
        # app_config
        self.app_desc = u"Audio Archiver"
        # for normal usage set to no!!!!!!
        self.app_windows = "no"
        self.app_errorfile = "error_audio_archiver.log"


def extract_filename(path_filename):
    """extract filename right from slash"""
    if ac.app_windows == "no":
        filename = path_filename[string.rfind(path_filename, "/") + 1:]
    else:
        filename = path_filename[string.rfind(path_filename, "\\") + 1:]
    return filename


def remove_forbidden_characters(my_string):
    """remove_forbidden_characters"""
    x = my_string.replace(u"'", "")
    x = x.replace(u"/", "")
    x = x.replace(u"&", "")
    x = x.replace(u"?", "")
    x = x.replace(u":", "")
    x = x.replace(u",", "")
    x = x.replace(u";", "")
    x = x.replace(u"+", "")
    x = x.replace(u"*", "")
    x = x.replace(u"=", "")
    x = x.replace(u"[", "")
    x = x.replace(u"]", "")
    x = x.replace(u"{", "")
    x = x.replace(u"}", "")
    x = x.replace(u"(", "")
    x = x.replace(u")", "")
    x = x.replace(u"%", "")
    x = x.replace(u"$", "")
    x = x.replace(u"§", "")
    x = x.replace(u"!", "")
    x = x.replace(u"#", "")
    x = x.replace(u"′", "")
    x = x.replace(u"^", "")
    x = x.replace(u"°", "")
    x = x.replace(u"~", "")
    return x


def remove_points(my_mp3):
    """remove additionally points in filename"""
    n = string.find(my_mp3, ".mp3")
    x = my_mp3[0:n]
    x = x.replace(u".", "")
    my_mp3_mod = x + ".mp3"
    return my_mp3_mod


def check_and_mod_filenames(self, mp3_files):
    """search for forbidden charakters in filenames, if found rename"""
    mp3_files_temp = []
    mp3_files_mod = []
    self.display_logging("\nOriginal files will be saved in...")
    #self.display_logging(datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S"))
    dir_orig = (os.path.dirname(mp3_files[0]) + "/audio_archiver_"
            + datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S") + "_orig")
    self.display_logging(dir_orig)

    self.display_logging("\nTemp files will be saved in...")
    #self.display_logging(datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S"))
    dir_temp = (os.path.dirname(mp3_files[0]) + "/audio_archiver_"
            + datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S") + "_temp")
    self.display_logging(dir_temp)

    self.display_logging("\nModified files will be saved in...")
    dir_mod = (os.path.dirname(mp3_files[0]) + "/audio_archiver_"
            + datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S") + "_mod")
    self.display_logging(dir_mod)
    try:
        os.mkdir(dir_orig)
        os.mkdir(dir_temp)
        os.mkdir(dir_mod)
    except Exception, e:
        self.display_logging("Error: %s" % str(e))

    self.display_logging("\nBackup files, check filenames...")
    # backup in orig
    for item in mp3_files:
        file_destination = dir_orig + "/" + extract_filename(item)
        self.display_logging("\n" + extract_filename(item))
        try:
            shutil.copy(item, file_destination)
        except Exception, e:
            self.display_logging("Error: %s" % str(e))

        # filename hacks
        # remove non ascii
        filename_mod = re.sub(r'[^\x00-\x7f]', r'', extract_filename(item))
        # remove forbidden characters
        filename_mod = remove_forbidden_characters(filename_mod)
        # remove points
        filename_mod = remove_points(filename_mod)
        # concatenate path and filename
        path_file_temp = dir_temp + "/" + filename_mod
        path_file_mod = dir_mod + "/" + filename_mod
        # loop thru files, move in temp
        if extract_filename(item) != filename_mod:
            try:
#TODO: for production, change from copy to move
                shutil.copy(item, path_file_temp)
                #shutil.move(item, path_file_mod)
            except Exception, e:
                self.display_logging("Error: %s" % str(e))
                continue
            self.display_logging("\nModified filename...")
            self.display_logging(filename_mod)
        else:
            #path_file_mod = dir_temp + "/" + extract_filename(item)
            try:
#TODO: for production, change from copy to move
                shutil.copy(item, path_file_temp)
                #shutil.move(item, path_file_mod)
            except Exception, e:
                self.display_logging("Error: %s" % str(e))
                continue
        # new file list
        mp3_files_temp.append(path_file_temp)
        mp3_files_mod.append(path_file_mod)
    return mp3_files_temp, mp3_files_mod, dir_temp, dir_mod


def mp3gain(self, mp3_file):
    """mp3-gain"""
    print u"mp3-File Gainanpassung"
    # start subprocess
    try:
        subprocess.Popen(["mp3gain", "-r", mp3_file],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
    except Exception, e:
        self.display_logging("Error: %s" % str(e))

        return None

    # search for success msg, if not found: -1
    #mp3gain_output = string.find(p[1], "98%")
    #mp3gain_output_2 = string.find(p[1], "99%")
    #mp3gain_output_1 = string.find(p[1], "written")
    #self.display_logging(p[1])
    #self.display_logging(mp3gain_output_1)
    # wenn gefunden, position, sonst -1
    #if mp3gain_output != -1 and mp3gain_output_1 != -1 and mp3gain_output_2 != -1:
    self.display_logging("\nmp3gain for: ")


def trim_silence(self, mp3_file, dir_mod):
    """trim_silence"""
    print u"mp3-File trim silence"
    dest_path_file = dir_mod + "/" + extract_filename(mp3_file)
    #self.display_logging(mp3_file)
    #self.display_logging(dest_path_file)
    #sox "$file_path_orig" -C 192.2 "$file" silence 1 0.1 1% reverse silence 1 0.1 1% reverse
    # start subprocess
    try:
        subprocess.Popen(["sox", mp3_file, "-C", "192.2", dest_path_file,
        "silence", "1", "0.1", "1%", "reverse",
        "silence", "1", "0.1", "1%", "reverse"],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
    except Exception, e:
        self.display_logging("Error: %s" % str(e))
        return None

    #self.display_logging(p)
    self.display_logging("\ntrimmed silence:")


class my_form(Frame):
    """Form"""
    def __init__(self, master=None):
        """create elements of form"""
        Frame.__init__(self, master)
        self.pack()
        #self.createWidgets()

        self.textBox = ScrolledText(self, height=15, width=100)
        self.textBox.pack()
        self.textBox.insert(END,
                "Work on audio files, this can take a while...\n")

        # registering callback
        self.listenID = self.after(400, self.lets_rock)
        #self.listenID = self.lets_rock

    def display_logging(self, log_message):
        """display messages in form, loading periodically """
        self.textBox.insert(END, log_message + "\n")

    def lets_rock(self):
        """man funktion"""
        print "lets rock"
        #log_data = None
        path_files = (
            os.environ['NAUTILUS_SCRIPT_SELECTED_FILE_PATHS'].splitlines())
        self.display_logging("Directory to work in...\n")
        self.display_logging(os.path.dirname(path_files[0]))
        self.display_logging("\nFiles to work on...")
        mp3_files = []
        for item in path_files:
            if string.rfind(item, ".mp3") == -1:
                # no mp3:
                continue
            mp3_files.append(item)
            self.display_logging(extract_filename(item))
        #    if os.path.isdir(p):
        #        print p
        #        self.display_logging(p, "")

        # filename hack
        mp3_filenames_temp, mp3_filenames_mod, dir_temp, dir_mod = (
                            check_and_mod_filenames(self, mp3_files))

        # trim silence
        self.display_logging("\nTrim silence, this can take a while...")
        for item in mp3_filenames_temp:
            trim_silence(self, item, dir_mod)
            self.display_logging(extract_filename(item))

        # mp3Gain
        self.display_logging("\nmp3Gain, this can take a while...")
        for item in mp3_filenames_mod:
            mp3gain(self, item)
            self.display_logging(extract_filename(item))
            #self.display_logging(item)

        # remove dir_temp
        try:
            shutil.rmtree(dir_temp)
            self.display_logging("\nTemp Directory removed...")
        except Exception, e:
            self.display_logging("Error: %s" % str(e))

if __name__ == "__main__":
    print "audio archiver started"
    ac = app_config()
    mything = my_form()
    mything.master.title("Audio Archiver")
    mything.mainloop()
    print "lets_lay_down"
    sys.exit()

