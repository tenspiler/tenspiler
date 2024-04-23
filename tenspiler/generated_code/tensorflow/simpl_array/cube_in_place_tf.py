
####### import statements ########
import tensorflow as tf

def cube_in_place_tf(arr, n):
    return (arr[:n]) * ((arr[:n]) * (arr[:n]))

def cube_in_place_tf_glued(arr, n):
    arr = tf.convert_to_tensor(arr, dtype=tf.int32)
    return cube_in_place_tf(arr, n)