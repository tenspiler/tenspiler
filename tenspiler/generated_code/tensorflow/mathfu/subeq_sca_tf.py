
####### import statements ########
import tensorflow as tf

def subeq_sca_tf(a, b, n):
    return (a[:n]) - (b)

def subeq_sca_tf_glued(a, b, n):
    a = tf.convert_to_tensor(a, dtype=tf.int32)
    return subeq_sca_tf(a, b, n)