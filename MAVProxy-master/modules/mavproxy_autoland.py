#new module for MAVproxy
'''
    autoland - displays autolanding HUD
'''

import math, numpy as np, sys, pygame

mpstate = None
App = None

class module_state(object):
    #stores the state of this module - values that the main process needs?
    def __init__(self):
        self.gps = [0,0]#lat, long
        self.ahrs = [0,0,0]#roll,pitch,yaw
        self.aspeed = 0
        self.alt = 0#altitude (m)
        self.lam = 0#localizer angle
        self.gam = 0#glideslope angle
        self.loc = [0,0,0]#postion vector in runway-centric coords
        self.RE = 6378100.0#earth radius in metres
        #constants defining the runway LOCATION and DIRECTION
        self.cos_eta_r = -.7071
        self.sin_eta_r = .7071
        self.LOC_LONG = -964850444
        self.LOC_LAT = 306379472
    def update_gps(self,lat,lon):
        self.gps = [lat,lon]
        #local GPS coords
        lat_rel = self.gps[0]-self.LOC_LAT
        long_rel = self.gps[1] - self.LOC_LONG
        #runway centric x-y-z coords in m?
        x = 1e-7*self.RE*(math.radians(lat_rel)*self.cos_eta_r + math.radians(long_rel)*self.sin_eta_r)
        y = 1e-7*self.RE*(-math.radians(lat_rel)*self.sin_eta_r + math.radians(long_rel)*self.cos_eta_r)
        self.loc = [x,y,-self.alt]
        #update gamma, lambda
        self.gam = math.degrees( math.atan(self.alt/abs(x)) )
        self.lam = math.degrees( math.atan(-1.0*y/abs(x)) )
    def update_ahrs(self,roll,pitch,yaw):
        self.ahrs = [roll, pitch, yaw]
    def update_aspeed(self,speed):
        self.aspeed = speed
    def update_alt(self,altitude):
        self.alt = altitude
    def get_gps(self):
        return self.gps
    def get_ahrs(self):
        return self.ahrs
    def get_aspeed(self):
        return self.aspeed
    def get_alt(self):
        return self.alt

class window:
    def __init__(self,x=0,y=0,h=0,w=0):
        self.xy = [x,y]#origin within the game window
        self.size = [h,w]#size within the game window in px
        self.xscale = 100#x limits of the window in fictional distance units, used for rendering distances on a scaled window
        self.AR = (1.0*w)/h
        self.origin = [0,0]
    def scale(self,sc):
        self.xscale = sc
    def set_origin(self,x,y):
        #set the origin for the transformed axis WITHIN this frame, the units are the same as xscale
        self.origin = [x,y]
    def render_line(self,screen,line,colorSpec=(255,0,0),thickness=2):
        #pygame.draw.line(self.screen, colorSpec, (line[0,0],line[0,1]),(line[1,0],line[1,1]),thickness)
        #line has format: ([[x0,y0],[x1,y1]]), and is in the scaled! frame
        #transform line to pixel values:
        [x0,y0] = self.convert_pt(line[0,0],line[0,1])
        [x1,y1] = self.convert_pt(line[1,0],line[1,1])
        pygame.draw.line(screen,colorSpec, (x0,y0),(x1,y1),thickness)
    def convert_pt(self,x,y):
        x1 = (x+self.origin[0])*self.size[0]/self.xscale + self.xy[0]
        y1 = (y+self.origin[1])*self.size[1]/(self.xscale*self.AR) + self.xy[1]
        return [x1,y1]

class HUD:
    def __init__(self):
        self._running = True
        pygame.init()
        #screen display properties
        self.size = (960,240)
        #HUD properties
        self.hudsize = (320,240)
        self.FOV_y = 30#degrees
        self.FOV_x = 40#degrees
        #topdown view properties
        self.topsize = (320,240)
        self.topWindow = window(320,0,320,240)
        self.topWindow.scale(750)
        self.topWindow.set_origin(100,281.25)
        self.posHist = []#store the position history
        self._newPos = False#flag that is True when new GPS data are received
        #side view properties
        self.sidesize = (320,240)
        self.sidePos = []#store the position history
        self.background = (0,0,0)#black background
        self.screen = pygame.display.set_mode(self.size)
        self.screen.fill(self.background)
        #store all data messages here:
        self.data = mpstate.autoland_state #do I need to declare this as a global? Not sure if passed by reference or not
        #font object for text
        self.font = pygame.font.Font(None,30)
        
    def on_event(self, event):
        if event.type == pygame.QUIT:
            self._running = False

    def on_loop(self):
        pass

    def on_render(self):
        #reset display
        self.screen.fill(self.background)
    #render HUD with status text and orientation
        #render status text
        w,h = self.font.size("")
        string = "THETA: "+str(self.data.ahrs[1])
        self.render_text(string,(0,0),0,self.hudsize)
        string = "PHI: "+str(self.data.ahrs[0])
        self.render_text(string,(0,h),size=self.hudsize)
        string = "ALT: "+str(self.data.alt)
        self.render_text(string,(0,2*h),size=self.hudsize)
        string = "LAMBDA: %.2f" % self.data.lam
        self.render_text(string,(0,3*h),size=self.hudsize)
        string = "GAMMA: %.2f" % self.data.gam
        self.render_text(string,(0,4*h),size=self.hudsize)
        #transform the pitch axis
        offset = self.hudsize[0]*((self.data.ahrs[1] + math.degrees(math.atan(math.sqrt(abs(self.data.alt))*.0002801)))/self.FOV_y)
        line_horizon = np.array([[0,0.5*self.hudsize[1]],[self.hudsize[0],0.5*self.hudsize[1]]]) + offset*np.array([[0,1],[0,1]])
        line_left = np.array([[0,0],[self.hudsize[0]*0.5,self.hudsize[1]*0.5]]) + offset*np.array([[0,1],[0,1]])
        line_right = np.array([[self.hudsize[0]*0.5,self.hudsize[1]*0.5],[self.hudsize[0],0]]) + offset*np.array([[0,1],[0,1]])
        #transform by roll:
        line_horizon = self.transform_roll(-self.data.ahrs[0],line_horizon,offset)
        line_left = self.transform_roll(-self.data.ahrs[0],line_left,offset)
        line_right = self.transform_roll(-self.data.ahrs[0],line_right,offset)
        #render visible attitude:
        #draw orientation lines
        self.render_line(line_left,(0,0,255))
        self.render_line(line_right,(0,0,255))
        #draw horizon line
        self.render_line(line_horizon,(0,255,0))
    #render top-down position and side view position
        #if not (self.posHist[0][0]==self.data.loc[0] && self.posHist[0][1]==self.data.loc):
        #update history
        self.render_text("X-Y",(self.hudsize[0],0),0)
        self.render_text("X: %.2f" % self.data.loc[0],(self.hudsize[0],h),0)
        self.render_text("Y: %.2f" % self.data.loc[1],(self.hudsize[0],2*h),0)
        self.render_line(np.array([[320,0],[320,240]]),(0,0,255),2)
        #draw the runway from (x = 100 to x = -100)
        self.topWindow.render_line(self.screen,np.array([[-100,0],[100,0]]),(255,255,0),4)
        #self.render_line(np.array([[self.hudsize[0],self.topsize[1]*0.5],[self.hudsize[0]+200.0*self.topsize[0]/750.0,self.topsize[1]*0.5]]),(255,255,0),4)
        if self._newPos:
            self._newPos = False
            #calculate topdown position
            pos = np.array([100,0]) - self.data.loc[0:2]
            pos = pos*np.array([self.topsize[0]/750.0, self.topsize[1]/562.5])
            pos = pos + np.array([self.hudsize[0],self.topsize[1]*0.5])
            self.posHist.insert(0,(pos[0],pos[1]))
            #calculate sideview position
            self.sidePos.insert(0,(pos[0]+self.topsize[0],self.sidesize[1]-20-self.data.alt*self.sidesize[1]/562.5))
        #remove earliest value if more than 100 are stored
        if len(self.posHist)>250:
            self.posHist.pop()
            self.sidePos.pop()
            #transform: X = (100-x)*320/750
            #           Y = (281.25-y)*240/562.5
        #draw trajectory
        if len(self.posHist)>1:
            pygame.draw.lines(self.screen, (255,0,0), False, self.posHist,2)
    #render side view (glideslope) trajecory
        self.render_text("X-Z",(self.hudsize[0]+self.topsize[0],0),0)
        self.render_text("Z: %.2f" % -self.data.loc[2],(self.hudsize[0]+self.topsize[0],h),0)
        self.render_line(np.array([[640,0],[640,240]]),(0,0,255),2)
        #render runway
        self.render_line(np.array([[self.hudsize[0]+self.topsize[0],self.sidesize[1]-20],[self.hudsize[0]+self.topsize[0]+200*self.topsize[0]/750.0,self.sidesize[1]-20]]),(255,255,0),4)
        if len(self.sidePos)>1:
            pygame.draw.lines(self.screen, (255,0,0), False, self.sidePos,2)
        #write to display
        pygame.display.flip()

    def render_line(self,line,colorSpec=(255,0,0),thickness=2):
        pygame.draw.line(self.screen, colorSpec, (line[0,0],line[0,1]),(line[1,0],line[1,1]),thickness)

    def render_text(self,string,location=(0,0),centered=0,size=(320,240)):
        if centered:
            w,h = self.font.size(string)
            textIm = self.font.render(string,0,(255,255,255))
            self.screen.blit(textIm,(0.5*size[0]-w/2+location[0],size[1]-h+location[1]))#draw text
        else:
            textIm = self.font.render(string,0,(255,255,255))
            self.screen.blit(textIm,(location[0],location[1]))#draw text

    def transform_roll(self,phi,line,offset=0):
        phi = math.radians(phi)
        d = np.array([[1],[1]])*np.array([self.hudsize[0]*0.5,self.hudsize[1]*0.5+offset])
        line_init = line - d
        newline = np.dot(np.array([[math.cos(phi), math.sin(phi)],[-math.sin(phi), math.cos(phi)]]),line_init.transpose())
        newline = d + newline.transpose()
        return newline

    def on_execute(self):
        if(self._running):
            #process events - kill the program is the only one so far
            for event in pygame.event.get():
                self.on_event(event)
            #make computations
            self.on_loop()
            #draw to screen
            self.on_render()
        else:
            self.on_cleanup

    def on_cleanup(self):
        pygame.quit()
        #sys.exit()

def name():
    return "autoland"

def description():
    return "Autolanding status GUI"

def init(_mpstate):
    global mpstate
    mpstate = _mpstate
    mpstate.autoland_state = module_state()#have to add this member to the mpstate class definition
    #do everything else that has to happen on startup
    #run the pygame stuff
    global App
    App = HUD()
    App.on_execute()

def unload():
    #mpstate.autoland_state =
    #delete this from the list of active modules in MPState
    #kill the pygame window
    App._running = False
    App.on_cleanup()

def mavlink_packet(msg):
    #handle an incoming mavlink packet
    mtype = msg.get_type()
    
    master = mpstate.master()
    state = mpstate.autoland_state
    if mtype == 'GLOBAL_POSITION_INT':
        App._newPos = True
        mpstate.autoland_state.update_gps(msg.lat,msg.lon)
        mpstate.autoland_state.update_alt(.001*msg.relative_alt)
        #module_state.alt = 0.001*msg.relative_alt#check units of this
    elif mtype == 'VFR_HUD':
        mpstate.autoland_state.update_aspeed(msg.airspeed)#check units, should be m/s
    elif mtype == 'ATTITUDE':
        mpstate.autoland_state.update_ahrs(msg.roll*57.30,msg.pitch*57.30,msg.yaw*57.30)#should be in deg
    App.on_execute()
