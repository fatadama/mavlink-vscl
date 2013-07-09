import cv2, cv, numpy as np,time, pickle, binarySearch as bs, os

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

def runCameraProc(conn,lock):
    #tell main that the process is running:
    conn.send('**.online.**')
    
    #create trackbars for HSV limits and blur value:
    
    #load camera
    cv2.namedWindow('camera')#camera image
    capture = cv2.VideoCapture(0)

    #add a new trackbar to trigger video logging on/off
    cv2.createTrackbar('record','camera',0,1,nothing)
    
    #open video writer for later use
    i = 1
    fname = 'rec' + str(i) +'.avi'
    for name in os.listdir('.'):
        if name == fname:
            i = i+1
            fname = 'rec' + str(i) +'.avi'
    frsize = (int(capture.get(cv.CV_CAP_PROP_FRAME_WIDTH)),int(capture.get(cv.CV_CAP_PROP_FRAME_HEIGHT)))
    vidWriter = cv2.VideoWriter(fname,cv.CV_FOURCC('M','J','P','G'),15,frsize)
    print vidWriter
    
    #variable that governs if video is being written:
    flag_writing = 0
    
    if not capture.isOpened:
        print "****Error: camera not found****"
    else:
        print capture
        flagShowVis = True
        while True:
            #read the camera image:
            ret,img = capture.read()
            if ret:
                flag_writing = cv2.getTrackbarPos('record','camera')
                #process frames
                
                if flag_writing==1:
                    img2 = np.copy(img)
                    cv2.putText(img,'RECORDING',(0,25),cv2.FONT_HERSHEY_DUPLEX,1,(0,0,255),thickness=2)
                    #write to VideoWriter
                    vidWriter.write(img2)
                
                cv2.imshow('camera',img)
                
            keyRet = cv2.waitKey(5)
            #see if user hits 'ESC' in opencv windows
            if keyRet==27:
                break
            #see if mavproxy has sent a command
            if conn.poll(0.05):
                t_last = time.clock()
                #if a command comes, process it
                #   **.kill.** - terminate process and close all windows
                #   **.update.** - transmit current [cx,cy] to the main process and reset the average
                #   **.bank.** - this is followed by the current MAV bank angle (deg)
                recvVal = conn.recv()
                if recvVal == '**.kill.**':
                    break
    cv2.destroyAllWindows()
    conn.send("cam off")        
    conn.close()
    #close recording file if still open:
    if vidWriter.isOpened():
        vidWriter.release()
