'''
    File name: VPFlasher.py
    Author: Travis Johnson
    Date last modified: 01/19/2019
    Python Version: 3.7.1
    Scapy Version: 2.4.2
'''

import sys
from tkinter import Tk, Menu, Toplevel, Label, BOTH
from scapy.all import sniff
from threading import Thread, main_thread
from time import time, sleep

class Flasher:

    def __init__(self):
        # create parent widget that'll live through the whole program
        self.root = Tk()
        self.root.withdraw()

        # menubar modification for macOS (to remove the default bloated Tkinter menu)
        menubar = Menu(self.root)
        appmenu = Menu(menubar, name='apple')
        menubar.add_cascade(menu=appmenu)
        appmenu.add_command(label='About VPFlasher') # inactive for now
        appmenu.add_separator()
        self.root['menu'] = menubar

        # initialized variables go here
        self.ring_has_timed_out = False
        self.call_status = "WAITING"
        self.ring_timeout = 0
        self.session_timeout = 0

        # bind callbacks to events
        self.root.bind("<<RingingOn>>", self.ringing_triggered)
        self.root.bind("<<RingingOff>>", self.ringing_terminated)
        self.root.bind("<<SessionOn>>", self.call_in_session) 
        self.root.bind("<<SessionOff>>", self.session_terminated)

        # start "main program here"
        self.waiting_for_payload_in_thread()

        self.root.mainloop()
    
###### BEGINNING OF PAYLOAD PROCESSING ######
    
    def connecting_payload(self):
        # return the readable string in a matched raw payload
        while True:
            # exit the program if main thread is terminated
            if not main_thread().is_alive():
                sys.exit(1)
            # reset the payload processing if ringing timed out
            if self.call_status == "RINGING" and time() >= self.ring_timeout:
                self.ring_has_timed_out = True
                return
            frame = sniff(count=1, filter='(tcp and dst port 5066) and (tcp[13] == 16 or tcp[13] == 24)', timeout=1)
            print("connecting_payload():", frame) # UNCOMMENT FOR DEBUG
            if len(frame) > 0:
                if frame[0].haslayer('Raw'):
                    try:
                        return frame[0].getlayer('Raw').load.decode("utf-8")
                    except UnicodeDecodeError:
                        return

    def has_session_keepalive_packet(self):
        # return the readable string in a matched raw payload
        sleep(0.5) # reduce processing load on CPU due to excessive matched frames traversing
        frame = sniff(count=1, filter='udp and ip[2:2] = 200', timeout=1)
        if len(frame) > 0:
            print("Session keepalive found at", time()) # UNCOMMENT FOR DEBUG
            return True
        else:
            return False

    def payload_found(self, payload, *payload_search_string):
        # return True if all strings in parameter are found in the payload
        try:
            if all(substring in payload for substring in payload_search_string):
                return True
        except TypeError:
            # return False when the connection payload functions return NoneType
            return False

    def waiting_for_payload_in_thread(self):
        self.wait_thread = Thread(target=self.waiting_for_payload)
        self.wait_thread.start()

    def waiting_for_payload(self):
        self.call_status = "WAITING"
        while self.call_status == "WAITING":  ### THIS IS THE ACTUAL START OF THE PROGRAM
            self.next_payload = self.connecting_payload()

            # set to 'RINGING' status
            if self.payload_found(self.next_payload, "SIP/2.0 180 Ringing"):
                print("It's ringing!") # UNCOMMENT FOR DEBUG
                self.call_status = "RINGING"
                self.ringing()

    def ringing(self):
        self.call_status = "RINGING"
        self.root.event_generate("<<RingingOn>>")
        self.ring_timeout = time() + 30
        self.ring_has_timed_out = False

        while self.call_status == "RINGING":
            # collect potential next matched payload
            self.next_payload = self.connecting_payload()

            # branch out to 'connected'
            # 'CSeq: 2' = Convo, 'CSeq: 1' = Sorenson, and 'CSeq: 102' = Purple/ZVRS 
            if ( self.payload_found(self.next_payload, "SIP/2.0 200 OK", "CSeq: 2 INVITE") or
                    self.payload_found(self.next_payload, "SIP/2.0 200 OK", "CSeq: 1 INVITE") or 
                    self.payload_found(self.next_payload, "SIP/2.0 200 OK", "CSeq: 102 INVITE") ):
                print("You're now connected!") # UNCOMMENT FOR DEBUG
                self.root.event_generate("<<RingingOff>>")
                self.in_call()
                break

            # branch out to 'cancelled'. This applies to calls not being timely answered too.
            # 'CSeq: 2' = Convo, 'CSeq: 1' = Sorenson, and 'CSeq: 102' = Purple/ZVRS 
            elif ( self.payload_found(self.next_payload, "SIP/2.0 200 OK", "CSeq: 2 CANCEL") or
                    self.payload_found(self.next_payload, "SIP/2.0 200 OK", "CSeq: 1 CANCEL") or
                    self.payload_found(self.next_payload, "SIP/2.0 200 OK", "CSeq: 102 CANCEL") ) or self.ring_has_timed_out:
                print("The call has been cancelled before you can answer.") # UNCOMMENT FOR DEBUG
                self.call_status = "WAITING"
                self.root.event_generate("<<RingingOff>>")
                break

            # branch out to 'busy'
            elif self.payload_found(self.next_payload, "SIP/2.0 486 Busy Here"):
                print("Okay! We see you're busy. :) ") # UNCOMMENT FOR DEBUG
                self.call_status = "WAITING"
                self.root.event_generate("<<RingingOff>>")
                break

            elif self.payload_found(self.connecting_payload(), "SIP/2.0 180 Ringing"):
                # ring for new inbound call in case of network disconnection and reconnection while ringing
                self.root.event_generate("<<RingingOff>>")
                self.ringing()


    def in_call(self):
        # process "keep-alive" payload in while loop. If not, call session has timed out
        self.call_status = "IN_CALL"
        self.root.event_generate("<<SessionOn>>")
        print("Call session has begun at", time()) # UNCOMMENT FOR DEBUG

        self.session_timeout = time() + 1

        while self.call_status == "IN_CALL":
            # just process the sniff() function in connected_payload() as it appears an UDP packet 
            # with IP header total length of exactly 200 bytes may be very unique to RTP traffic

            # exit the program if main thread is terminated
            if not main_thread().is_alive():
                sys.exit(1)
            
            # resume to listen for new incoming call if session terminated
            if time() >= self.session_timeout:
                print("Call session has timed out at ", time())  # UNCOMMENT FOR DEBUG
                self.call_status = "WAITING"
            
            # extend timeout value as long as there exists a keepalive packet
            if self.has_session_keepalive_packet():
                self.session_timeout = time() + 1   

        self.root.event_generate("<<SessionOff>>")

###### END OF PAYLOAD PROCESSING ######
#
###### BEGINNING OF GUI BUILDING ######

    def create_flasher_ui(self):
        self.flash_widget = Toplevel(master=self.root)
        self.flash_widget.title("")
        self.flash_widget_width = self.flash_widget.winfo_screenwidth()
        self.flash_widget_height = self.flash_widget.winfo_screenheight()
        self.flash_widget.wm_resizable(width=False, height=False)
        # self.flash_widget.configure(background='#76B53E') # green flashing widget
        self.flash_widget.configure(background='Blue') # blue flashing widget
        self.flash_widget.attributes('-alpha', 0.7)
        self.flash_widget.geometry("0x0+0+0")
        self.flash_widget.protocol("WM_DELETE_WINDOW", self.terminate_program)

    def flashing_widget(self):
        self.flash_widget.after(100, self.flash_widget.geometry, "{0}x{1}+0+0".format(self.flash_widget_width, self.flash_widget_height))
        self.flash_widget.after(200, self.flash_widget.geometry, "0x0+0+0")
        self.flash_widget.after(300, self.flashing_widget)

    def create_in_call_ui(self):
        self.in_call_widget = Toplevel(master=self.root)
        self.in_call_widget.title("CALL IN SESSION")
        self.in_call_widget.attributes('-alpha', 0.8)
        self.in_call_widget_width = int(self.in_call_widget.winfo_screenwidth() / 4.5)
        self.in_call_widget_height = int(self.in_call_widget.winfo_screenheight() / 4 )
        self.in_call_widget.geometry("{0}x{1}+0+0".format(self.in_call_widget_width, self.in_call_widget_height))
        self.in_call_widget.wm_resizable(width=False, height=False)
        self.in_call_widget.protocol("WM_DELETE_WINDOW", self.terminate_program)

        # create a label inside the widget 
        self.in_call_text = Label(self.in_call_widget, text="CALL IN SESSION")
        self.in_call_text.configure(
            font=("TkDefaultFont", 20, "bold"),
            foreground="white",
            background="red",
            )
        self.in_call_text.pack(fill=BOTH, expand=1)

###### END OF GUI BUILDING ######
#
###### BEGINNING OF EVENT BINDING ######

    def ringing_triggered(self, event):
        self.create_flasher_ui()
        self.flashing_widget()

    def ringing_terminated(self, event):
        self.flash_widget.destroy()

    def call_in_session(self, event):
        self.create_in_call_ui()

    def session_terminated(self, event):
       self.in_call_widget.destroy()

###### END OF EVENT BINDING ######
#
###### BEGINNING OF MISCELLANEOUS FUNCTIONS ######

    def terminate_program(self):
        sys.exit(1)

###### END OF MISCELLANEOUS FUNCTIONS ######

if __name__ == "__main__":
    Flasher()
