#!/usr/bin/env python

"""
"""


# Adapted from
# https://github.com/Lasagne/Recipes/blob/7b4516e722aab6055841d02168eba049a11fe6da/modelzoo/vgg16.py
# https://github.com/Lasagne/Recipes/blob/7b4516e722aab6055841d02168eba049a11fe6da/modelzoo/vgg19.py



from lasagne.layers import InputLayer, DenseLayer, DropoutLayer, NonlinearityLayer, batch_norm
from lasagne.layers import Conv3DLayer, MaxPool3DLayer
from lasagne.nonlinearities import rectify, softmax
from lasagne.init import GlorotUniform


def build_model(input_var=None):

    # Define common parameters
    input_shape = (None, 1, 145, 182, 155)

    n_filters = {'l1': 32,
                 'l2': 64,
                 'l3': 128,
                 'l4': 256,
                 'l5': 256,
                 'fc': 512}

    kws_conv = {'filter_size': (3,3,3),
                'stride': (1,1,1),
                'pad': 'same', # (1,1,1) -- same might be faster
                'W': GlorotUniform(gain='relu'),
                'nonlinearity': rectify,
                'flip_filters': False}

    kws_maxpool = {'pool_size': (2,2,2),
                   'stride': (2,2,2)}
                   # 'pad': (0,0,0)} -- should be defined per layer

    kws_dense = {'W': GlorotUniform(gain='relu'),
                 'nonlinearity': rectify}

    kws_dropout = {'p': 0.5}


    # Define network architecture
    net = InputLayer(input_shape, input_var, name='input')

    # ----------- 1st layer group ---------------
    net = batch_norm(Conv3DLayer(net, n_filters['l1'], name='conv1a', **kws_conv))
    net = MaxPool3DLayer(net, name='pool1', pad=(1,0,1), **kws_maxpool)

    # ------------- 2nd layer group --------------
    net = batch_norm(Conv3DLayer(net, n_filters['l2'], name='conv2a', **kws_conv))
    net = MaxPool3DLayer(net, name='pool2', pad=(1,1,0), **kws_maxpool)

    # ----------------- 3rd layer group --------------
    net = batch_norm(Conv3DLayer(net, n_filters['l3'], name='conv3a', **kws_conv))
    net = batch_norm(Conv3DLayer(net, n_filters['l3'], name='conv3b', **kws_conv))
    net = MaxPool3DLayer(net, name='pool3', pad=(1,0,1), **kws_maxpool)

    # ----------------- 4th layer group --------------
    net = batch_norm(Conv3DLayer(net, n_filters['l4'], name='conv4a', **kws_conv))
    net = batch_norm(Conv3DLayer(net, n_filters['l4'], name='conv4b', **kws_conv))
    net = MaxPool3DLayer(net, name='pool4', pad=(1,1,0), **kws_maxpool)

    # ----------------- 5th layer group --------------
    net = batch_norm(Conv3DLayer(net, n_filters['l5'], name='conv5a', **kws_conv))
    net = batch_norm(Conv3DLayer(net, n_filters['l5'], name='conv5b', **kws_conv))
    net = MaxPool3DLayer(net, name='pool5', **kws_maxpool)

    # ----------------- FC layers group --------------
    net = batch_norm(DenseLayer(net, n_filters['fc'], name='fc6', **kws_dense))
    net = DropoutLayer(net, name='fc6_dropout', **kws_dropout)

    net = batch_norm(DenseLayer(net, n_filters['fc'], name='fc7', **kws_dense))
    net = DropoutLayer(net, name='fc7_dropout', **kws_dropout)

    # ----------------- Output layers group --------------
    net = batch_norm(DenseLayer(net, 3, nonlinearity=None, name='fc8'))
    net = NonlinearityLayer(net, nonlinearity=softmax, name='prob')

    return net


