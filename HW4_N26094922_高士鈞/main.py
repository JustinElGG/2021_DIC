import cv2
import numpy as np

pre_1d = []
pos_1d = []

img_in = cv2.imread('./image.jpg', cv2.IMREAD_GRAYSCALE)
img_in = cv2.resize(img_in, (128, 128))
hight, width = img_in.shape
img = np.zeros((130, 130))
img[1:129, 1:129] = img_in
img = img.astype(np.uint8)
img_out_pre = img[1:129, 1:129]

for i in range(0, 128):
    hex_arr = ['{:02X}'.format(i)+'\n' for i in img_out_pre[i]]
    pre_1d.extend(hex_arr)
fp1 = open("img.dat", "w")
fp1.writelines(pre_1d)


img = cv2.medianBlur(img, 3)
img_out_pos = img[1:129, 1:129]
for i in range(0, 128):
    hex_arr = ['{:02X}'.format(i)+'\n' for i in img_out_pos[i]]
    pos_1d.extend(hex_arr)
fp2 = open("golden.dat", "w")
fp2.writelines(pos_1d)

print('Done.')