####### import statements ########
import mlx.core as mx


def color_burn_8_mx(base, active):
    return mx.where(mx.equal(active, 0), 255, (255) - (((255) - (base)) // (active)))


def color_burn_8_mx_glued(base, active):
    base = mx.array(base, mx.uint8)
    active = mx.array(active, mx.uint8)
    return color_burn_8_mx(base, active)


import os
import time

import cv2

####### more import statements for benchmarking ########
import numpy as np

####### setup for benchmarking ########
rng = np.random.default_rng(1)

folder = "./data/"

img_files = [
    os.path.join(folder, f)
    for f in os.listdir(folder)
    if os.path.isfile(os.path.join(folder, f))
]

bases = []
actives = []

for _file in img_files:
    img = cv2.imread(_file, cv2.IMREAD_GRAYSCALE).astype(np.uint8)
    img[img == 0] = 1
    rnd = (rng.random(img.shape, dtype=np.float32) * 255).astype(np.uint8)
    rnd[rnd == 0] = 1
    bases.append(img)
    actives.append(rnd)

####### runner. need to manually update for each file ########
runs = 10
times = []
for _ in range(runs):
    total_time = 0
    for i in range(len(bases)):
        b = mx.array(bases[i], mx.uint8)
        a = mx.array(actives[i], mx.uint8)
        start_time = time.perf_counter()
        mx.eval(color_burn_8_mx(b, a))
        end_time = time.perf_counter()
        total_time += (end_time - start_time) * 1000

    times.append(total_time)

times = np.array(times)

print("color_burn_8_mx")
print(f"{np.average(times)} {np.std(times)}")
print(f"{np.average(times)} {np.std(times)}")
