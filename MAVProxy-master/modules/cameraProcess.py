import cv2, cv, numpy as np,time, pickle

#called from mavproxy when 'camera' is entered into the console.
#when runCameraProc is called, it initializes the camera streaming window and trackbars
#   that control the thresholding for HSV filtering. Image is HSV filtered and the largest
#   resulting contour is centroided. A moving average of centroids is maintained until mavproxy
#   requests an update, which should occur at 1 Hz. The average centroid is then used to
#   look up the appropriate action in the Q-matrix.
#
#development progress: currently, q-matrix has not been implemented.

def nothing(args):
    pass

def settingUpdate(hsvL,hsvU,blurRad):
    hsvL[0] = cv2.getTrackbarPos('hLower','sliders')
    hsvL[1] = cv2.getTrackbarPos('sLower','sliders')
    hsvL[2] = cv2.getTrackbarPos('vLower','sliders')
    #ensure that the upper bound is greater than the lower bound:
    hsvU[0] = np.amax(np.array([cv2.getTrackbarPos('hUpper','sliders'),hsvL[0]+1]))
    hsvU[1] = np.amax(np.array([cv2.getTrackbarPos('sUpper','sliders'),hsvL[1]+1]))
    hsvU[2] = np.amax(np.array([cv2.getTrackbarPos('vUpper','sliders'),hsvL[2]+1]))
    blurRad = cv2.getTrackbarPos('blur','sliders')
    return

def runCameraProc(conn):
    #initialize variables for HSV limits and blur radius:
    blurRad = 3#image blur radius
    hsvl = np.array([0,96,74])#lower HSV cutoff
    hsvu = np.array([29,255,255])#upper HSV cutoff
    #numFrames: the number of frames processed in the current moving average calculation
    numFrames = 0
    #cxbar, cybar: average centroid location in the frame
    [cxbar,cybar] = [0,0]
    #numBanks: the number of bank angles received from the aircraft (degrees) for moving average calculation
    numBanks = 0
    #phibar: the moving average bank angle, (deg)
    phibar = 0
    #ACTION: the action to take. is +/-2, 0
    action = 0
    #create trackbars for HSV limits and blur value:
    cv2.namedWindow('sliders')
    cv2.createTrackbar('hLower', 'sliders', hsvl[0], 255, nothing)
    cv2.createTrackbar('sLower', 'sliders', hsvl[1], 255, nothing)
    cv2.createTrackbar('vLower', 'sliders', hsvl[2], 255, nothing)
    cv2.createTrackbar('hUpper', 'sliders', hsvu[0], 255, nothing)
    cv2.createTrackbar('sUpper', 'sliders', hsvu[1], 255, nothing)
    cv2.createTrackbar('vUpper', 'sliders', hsvu[2], 255, nothing)
    cv2.createTrackbar('blur','sliders',blurRad,15,nothing)
    #load camera
    cv2.namedWindow('camera')#camera image
    capture = cv2.VideoCapture(0)
    if not capture.isOpened:
        print "****Error: camera not found****"
    else:
        print capture
        flagShowVis = True
        while True:
            #read the camera image:
            ret,img = capture.read()
            if ret:
                #update settings from sliders:
                settingUpdate(hsvl,hsvu,blurRad)
                #process frames
                
                #blur the image to reduce color noise: (5 x 5)
                img = cv2.blur(img,(blurRad,blurRad))
                
                #convert image to HSV
                hsv = cv2.cvtColor(img,cv2.COLOR_BGR2HSV)
                #threshold the image using the HSV lower and upper bounds
                thresh = cv2.inRange(hsv,hsvl,hsvu)
                thresh2 = np.copy(thresh)
                #find contours in the thresholded image:
                contours,hierarchy = cv2.findContours(thresh,cv2.RETR_LIST,cv2.CHAIN_APPROX_SIMPLE)
                
                #pickle contours to deal with a bug in opencv 2.4.3
                tmp = pickle.dumps(contours)
                contours = pickle.loads(tmp)
                
                #get the contour with the largest area:
                max_area = -1
                best_cnt = np.array([])
                cx,cy = (0,0)

                #loop over the contours and find the one with the largest area:
                for cnt in contours:
                        area = cv2.contourArea(cnt)
                        if area>max_area:
                                max_area = area
                                best_cnt = cnt
                                
                #check that the size of the best contour is not empty
                if np.shape(best_cnt)[0]>0:
                        #find the centroid of best contour
                        M = cv2.moments(best_cnt)
                        #check that the divisor moment is nonzero; if it is, set the location to (0,0)
                        if M['m00']>0:
                                cx,cy = int(M['m10']/M['m00']),int(M['m01']/M['m00'])
                        else:
                                cx,cy = (0,0)
                #update the moving averages:
                if cx>0 and cy>0:
                    #ensure that cx>0, cy>0 in case centroid drops out
                    numFrames = numFrames+1
                    cxbar = (cx+cxbar*(numFrames-1))/numFrames
                    cybar = (cy+cybar*(numFrames-1))/numFrames
                if flagShowVis:
                    #draw circle at contour centroid:
                    cv2.circle(img,(cx,cy),3,(0,255,0),-1)
                    cv2.imshow('camera',img)
                else:
                    cv2.circle(thresh2,(cx,cy),3,(0,255,0),-1)
                    cv2.imshow('camera',thresh2)
                    
            keyRet = cv2.waitKey(5)
            #see if user hits 'ESC' in opencv windows
            if keyRet==27:
                break
            elif keyRet==32:
                flagShowVis = not flagShowVis
            #see if mavproxy has sent a command
            if conn.poll(0.05):
                #if a command comes, process it
                #   **.kill.** - terminate process and close all windows
                #   **.update.** - transmit current [cx,cy] to the main process and reset the average
                #   **.bank.** - this is followed by the current MAV bank angle (deg)
                recvVal = conn.recv()
                if recvVal == '**.kill.**':
                    break
                elif recvVal == '**.update.**':
                    #use cxbar, cybar to compute the appropriate bank angle.
                    #INSERT Q-MATRIX LOOKUP HERE
                    #reset cxbar, cybar
                    numFrames = 0
                    [cxbar,cybar] = [0,0]
                    #reset phibar, numBanks
                    numBanks = 0
                    phibar = 0
                    #return -2 (decrease bank angle),0 (do nothing),2 (increase bank angle)
                    print time.clock(),action,'  camProcess'
                    conn.send(action)
                    action = action+2
                    if action>2:
                        action = -2
                elif recvVal == '**.bank.**':
                    #read in bank angle from process:
                    if conn.poll(0.05):
                        #update moving average calculation
                        numBanks = numBanks+1
                        phi = conn.recv()
                        phibar = (phi+phibar*(numBanks-1))/numBanks
                    else:
                        print 'camProcess did not receive bank angle from MAVProxy'
    cv2.destroyAllWindows()
    conn.send("cam off")        
    conn.close()
