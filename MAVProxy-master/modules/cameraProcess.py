import cv2, cv, numpy as np,time, pickle

def runCameraProc(conn):
    #load camera
    cv2.namedWindow('camera')#camera image
    capture = cv2.VideoCapture(0)
    if not capture.isOpened:
        print "****Error: camera not found****"
    else:
        print capture
        while True:
            #read the camera image:
            ret,img = capture.read()
            #process frames
            #grab images and display
            if ret:
                cv2.imshow('camera',img)
            keyRet = cv2.waitKey(5)
            if keyRet==27:
                break
            if conn.poll(0.05):
                recvVal = conn.recv()
                if recvVal == 'kill':
                    break
    conn.send("cam off")        
    conn.close()
