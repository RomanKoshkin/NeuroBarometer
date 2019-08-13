import wx
import wx.lib.inspection

import numpy as np
import threading
import time

from ctypes import*
mydll = cdll.LoadLibrary("C:/Users/1/inpoutx64.dll")

import sounddevice as sd
# import soundfile as sf
import simpleaudio as sa

from pydub import AudioSegment
from pydub.playback import play
from pydub.generators import Sine




class AppWindow(wx.Frame):

    def __init__(self, parent):
        super(AppWindow, self).__init__(parent)
        wx.Frame.__init__(self, None, title='NeuroBarometer') #, style=style
        self.Maximize()
        self.winsize = self.GetSize()
        print(self.winsize)
        self.SetBackgroundColour('black')

        # style=(wx.FULLSCREEN_NOMENUBAR|wx.FULLSCREEN_NOMENUBAR|wx.FULLSCREEN_NOTOOLBAR|wx.FULLSCREEN_NOCAPTION)
        
        # self.Show()
        # self.ShowFullScreen(True)

        self.panel = wx.Panel(self, size=self.winsize)
        self.panel.SetBackgroundColour('black')
        self.panel.Show()

        
        
        self.text = wx.StaticText(self.panel, label="WHEN READY, PRESS CTRL + S", pos=(1000,600))
        self.text.SetForegroundColour('white')
 

        self.InitUI()

        self.ad_counter = 0
        self.normal_vol = 0        
        if self.normal_vol==1:
            print('HIGH VOLUME OF BACKGROUND ADS')
            self.ads = [
                'C:/Users/1/Desktop/Daria/newsnds/silence.wav',
                'C:/Users/1/Desktop/Daria/newsnds/23_12.wav',
                'C:/Users/1/Desktop/Daria/newsnds/24_12.wav',
                'C:/Users/1/Desktop/Daria/newsnds/25_12.wav',
                'C:/Users/1/Desktop/Daria/newsnds/30_12.wav',
                'C:/Users/1/Desktop/Daria/newsnds/39_12.wav',
                'C:/Users/1/Desktop/Daria/newsnds/47_12.wav',
                'C:/Users/1/Desktop/Daria/newsnds/3_12.wav',
                'C:/Users/1/Desktop/Daria/newsnds/14_12.wav',
                'C:/Users/1/Desktop/Daria/newsnds/15_12.wav',
                'C:/Users/1/Desktop/Daria/newsnds/19_12.wav',                              
                'C:/Users/1/Desktop/Daria/newsnds/super1.wav',                  
                'C:/Users/1/Desktop/Daria/newsnds/super2.wav',   
                ]
        else:
            print('LOW VOLUME OF BACKGROUND ADS')
            self.ads = [
                'C:/Users/1/Desktop/Daria/newsnds/silence.wav',
                'C:/Users/1/Desktop/Daria/newsnds/39_12_-6db.wav',
                'C:/Users/1/Desktop/Daria/newsnds/47_12_-6db.wav',
                'C:/Users/1/Desktop/Daria/newsnds/3_12_-6db.wav',
                'C:/Users/1/Desktop/Daria/newsnds/14_12_-6db.wav',
                'C:/Users/1/Desktop/Daria/newsnds/15_12_-6db.wav',
                'C:/Users/1/Desktop/Daria/newsnds/19_12_-6db.wav',
                'C:/Users/1/Desktop/Daria/newsnds/23_12_-6db.wav',
                'C:/Users/1/Desktop/Daria/newsnds/24_12_-6db.wav',
                'C:/Users/1/Desktop/Daria/newsnds/25_12_-6db.wav',
                'C:/Users/1/Desktop/Daria/newsnds/30_12_-6db.wav',
                'C:/Users/1/Desktop/Daria/newsnds/super1.wav',                  
                'C:/Users/1/Desktop/Daria/newsnds/super2.wav',                
                ]     

        self.cb = []
        self.questions = [
        # 'Насколько внимательно вы прослушали эту рекламу?',
        'Оцените положительные эмоции, которые вызывает реклама',
        'Оцените отрицательные эмоции, которые вызывает реклама?',
        'Насколько реклама привлекла ваше внимание?',
        'Насколько вы поняли содержание рекламы?',
        'Насколько интересен текст рекламы?',
        'Насколько вам интересен рекламируемый продукт?',
        'Насколько реклама скучная?',
        'Насколько затянутой вам показалась реклама?',
        'Насколько реклама креативная?'
        ]

    def ShowText(self):
        # self.panel.Destroy()
        # self.text.Destroy()
        a = wx.CheckBox(self, label="asdfas", pos=(100,100), size=(10,10))
        a.SetForegroundColour('white')
        # self.panel = wx.Panel(self, size=self.winsize)
        # self.panel.SetForegroundColour('white')
        # self.panel.SetBackgroundColour('black')
        # self.panel.Show()
        # self.panel.Refresh()

        # # wx.CheckBox(self.panel, label="asdfas", pos=(0,0))

        # self.qtext = []
        # for i in range(10):
        #     tmp_txt = wx.StaticText(self.panel, pos=(330,40+30*i))
        #     tmp_txt.SetForegroundColour('white')
        #     tmp_txt.Refresh()
        #     self.qtext.append(tmp_txt)
        #     self.qtext[i].SetLabel(self.questions[i])
        
        # for j in range(10):
        #     wx.StaticText(self.panel, label=str(j+1), pos=(10+30*j, 10))
        
        # for i in range(10):
        #     cb_row = []
        #     for j in range(10):
        #         cb_tmp = wx.CheckBox(self.panel, label=str(i)+str(j), pos=(5+30*j, 40+30*i))
        #         cb_tmp.SetForegroundColour('black')
        #         cb_row.append(cb_tmp)
        #     self.cb.append(cb_row)
        
        # self.Bind(wx.EVT_CHECKBOX,self.onChecked)
        # self.panel.Show()

    def onChecked(self, e):
        cb = e.GetEventObject()
        clicked_box = list(map(int, cb.GetLabel()))
        self.checkForDoubleClicks(clicked_box)

    def checkForDoubleClicks(self, clicked_box):
        cur_clicked = self.cb[clicked_box[0]][clicked_box[1]].GetValue()
        i = clicked_box[0]
        j = clicked_box[1]

        self.qtext[i].SetForegroundColour((255,0,0,0))
        self.qtext[i].Refresh()
        print('Checkbox {:2d} {:2d} is clicked {}'.format(i,j,cur_clicked))
        others = [x for x in range(10) if x!=j]
        for J in others:
            self.cb[i][J].SetValue(False)

    def InitUI(self):
        menubar = wx.MenuBar()

        fileMenu = wx.Menu()
        fileMenu.Append(wx.ID_NEW, '&Full Screen')
        fileMenu.Append(wx.ID_OPEN, '&Open')
        fileMenu.Append(wx.ID_SAVE, '&Save')
        # fileMenu.Append(wx.ID_ANY, '&Quit')
        fileMenu.AppendSeparator()

        # http://zetcode.com/wxpython/menustoolbars/
        imp = wx.Menu()
        imp.Append(wx.ID_ANY, 'Import newsfeed list...')
        imp.Append(wx.ID_ANY, 'Import bookmarks...')
        imp.Append(wx.ID_ANY, 'Import mail...')

        fileMenu.Append(wx.ID_ANY, 'I&mport', imp)

        fsi = wx.MenuItem(fileMenu, wx.ID_ANY, '&Full Screen\tCtrl+F')
        qmi = wx.MenuItem(fileMenu, wx.ID_ANY, '&Abort\tCtrl+A')
        qme = wx.MenuItem(fileMenu, wx.ID_ANY, '&Start\tCtrl+S')
        fileMenu.Append(fsi)
        fileMenu.Append(qmi)
        fileMenu.Append(qme)

        self.Bind(wx.EVT_MENU, self.OnQuit, qmi)
        self.Bind(wx.EVT_MENU, self.OnTest, qme)
        self.Bind(wx.EVT_MENU, self.ShowText, fsi)

        menubar.Append(fileMenu, '&File')
        self.SetMenuBar(menubar)

        self.SetSize((350, 250))
        self.SetTitle('NeuroBarometer')
        self.Centre()

   
    def OnQuit(self, e):
        self.Close()

    def OnTest(self, e):
        thread = threading.Thread(target=self.beeps, args=())
        thread.daemon = True
        thread.start()

    def OnFullScreen(self, e):
        print('fullscreen')
        self.text.SetLabel('new text')

    def beeps(self):
        self.text.SetLabel('GET READY FOR TEXT {:2d}'.format(self.ad_counter))
        time.sleep(2)
        self.text.SetLabel('+')
        times = []
        sound_latency = 0.02 # hardware sound latency
        fs = 44100
        T = 0.05
        f = [440, 760, 1990]
        ISIs = [0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.8]
        ISIs = [x - 0.25 for x in ISIs]
        p = [0.40, 0.24, 0.07, 0.07, 0.06, 0.05, 0.04, 0.03, 0.02, 0.01, 0.01]
        
        if self.ad_counter < len(self.ads):
            bg_file_name = self.ads[self.ad_counter]
            print('Current ad: {:2d}'.format(self.ad_counter))
        else:
            print('This was the last text')
            self.text.SetLabel('THANK YOU!')
            return None
        ramp_s = 0.005

        data = generate_tones(fs, T, f)
        data = rise_n_fall(data, ramp_s, fs)

        bg = background(bg_file_name) # instantiate background player in a separate thread
        bg.start()        # start background audio
        beep_start = time.time()
        while bg.running==True: # while the background is playing, play probes with random ISIs
            for ch in [0, 1, 2]: # 3 ================================================================= # jj / ch
                if bg.running==False:
                    break
                for z in range(7): #=============================# 7 / 10 
                    t0 = time.time()
                    # ch = np.random.choice([0, 1, 2], p=[0.6, 0.2, 0.2]) #++++++++++++++++++++++++++++++++++++++++
                    if ch==0: port_sinal = 1
                    if ch==1: port_sinal = 2 # 2
                    if ch==2: port_sinal = 4 # 4
                    print(time.time()-beep_start-sound_latency)
                    beep_start = time.time()
                    if bg.running==False:
                        break
                    sd.play(data[ch], fs)

                    time.sleep(0.22) # Это чтобы начало проб совпало с триггерами

                    mydll.Out32(0x378, port_sinal)
                    time.sleep(0.01)
                    mydll.Out32(0x378, 0)
                    
                    x = np.asscalar(np.random.choice(ISIs, p=p, size=1))
                    time.sleep(x-sound_latency) # correct ISIs for hardware sound latency
                    t1 = time.time()
                    print('elapsed {:2f} \t true {:2f} \t error {:2f} '.format(t1-t0, x, np.abs(t1-t0-x)))
                    times.append(t1-t0)

        # self.ShowText()
        print('Background audio is over')
        self.text.SetLabel('TEXT {:2d} IS OVER. RATE IT NOW. \nWHEN READY TO CONTINUE, PRESS CTRL + S'.format(self.ad_counter))
        self.ad_counter += 1
        bg.join()
  

class background(threading.Thread):
    
    def __init__(self, bg_file_name):
        super(background, self).__init__()
        self.running = False
        self.fname = bg_file_name
        self._stop_event = threading.Event()

    def run(self):
        self.running = True
        # mysong = AudioSegment.from_wav(self.fname)
        # play(mysong)

        # data, fs = sf.read(self.fname, dtype='float32')
        # sd.play(data,fs)
        # sd.wait()
        wo = sa.WaveObject.from_wave_file(self.fname)
        
        mydll.Out32(0x378, 8)
        time.sleep(0.01)
        mydll.Out32(0x378, 0)

        po = wo.play()
        po.wait_done()

        mydll.Out32(0x378, 8)
        time.sleep(0.01)
        mydll.Out32(0x378, 0)

        self.running = False
        print('BG STOPPED')
        
    def stop(self):
        self._stop_event.set()

def generate_tones(fs, T, f):
    volume = 0.99
    t = np.linspace(0,T,fs*T)
    data = []
    for i in range(len(f)):
        data.append(volume*np.sin(2*np.pi*f[i]*t)) # previously 0.7 
    return data

def rise_n_fall(data, ramp_s, fs):
    ramp = np.asscalar(np.round(ramp_s/(1/fs)).astype('int'))
    print(ramp)
    for i in range(3):
        data[i][0:ramp] = data[i][0:ramp]*np.linspace(0,1,ramp)
        data[i][-ramp:] = data[i][-ramp:]*np.linspace(1,0,ramp)
    return data


def main():
    app = wx.App()
    ex = AppWindow(None)
    ex.Show()
    # wx.lib.inspection.InspectionTool().Show()
    app.MainLoop()


if __name__ == '__main__':
    main()