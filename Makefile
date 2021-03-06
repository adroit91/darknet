#
# Default make builds both original darknet, and its CPP equivalent darknet-cpp
# make darknet - only darknet (original code)
# make darknet-cpp - only the CPP version
# 
# CPP version supports OpenCV3. Tested on Ubuntu 16.04
#
# OPENCV=1 (C++ && CV3, or C && CV2 only - check with pkg-config --modversion opencv)
# When building CV3 and C version, will get errors like
# ./obj/image.o: In function `cvPointFrom32f':
# /usr/local/include/opencv2/core/types_c.h:929: undefined reference to `cvRound'
#
#

GPU=1
CUDNN=1
OPENCV=1
DEBUG=1

ARCH= --gpu-architecture=compute_52 --gpu-code=compute_52

# C Definitions

VPATH=./src/
EXEC=darknet
OBJDIR=./obj/
CC=gcc

# C++ Definitions
EXEC_CPP=darknet-cpp
OBJDIR_CPP=./obj-cpp/
CC_CPP=g++
CFLAGS_CPP=-Wno-write-strings

NVCC=nvcc -ccbin /usr/bin/g++
OPTS=-Ofast
LDFLAGS= -lm -pthread 
COMMON= 
CFLAGS=-Wall -Wfatal-errors 



ifeq ($(DEBUG), 1) 
OPTS=-O0 -g
endif

CFLAGS+=$(OPTS)

ifeq ($(OPENCV), 1) 
COMMON+= -DOPENCV
CFLAGS+= -DOPENCV
LDFLAGS+= `pkg-config --libs opencv` 
COMMON+= `pkg-config --cflags opencv` 
endif

# Place the IPP .a file from OpenCV here for easy linking
LDFLAGS += -L/usr/local/share/OpenCV/3rdparty/lib

ifeq ($(GPU), 1) 
COMMON+= -DGPU -I/usr/local/cuda/include/
CFLAGS+= -DGPU
LDFLAGS+= -L/usr/local/cuda/lib64 -lcuda -lcudart -lcublas -lcurand
endif

ifeq ($(CUDNN), 1) 
COMMON+= -DCUDNN 
CFLAGS+= -DCUDNN
LDFLAGS+= -lcudnn
endif

OBJ=gemm.o utils.o cuda.o convolutional_layer.o list.o image.o activations.o im2col.o col2im.o blas.o crop_layer.o dropout_layer.o maxpool_layer.o softmax_layer.o data.o matrix.o network.o connected_layer.o cost_layer.o parser.o option_list.o darknet.o detection_layer.o captcha.o route_layer.o writing.o box.o nightmare.o normalization_layer.o avgpool_layer.o coco.o dice.o yolo.o detector.o layer.o compare.o classifier.o local_layer.o swag.o shortcut_layer.o activation_layer.o rnn_layer.o gru_layer.o rnn.o rnn_vid.o crnn_layer.o demo.o tag.o cifar.o go.o batchnorm_layer.o art.o region_layer.o reorg_layer.o super.o voxel.o tree.o
ifeq ($(GPU), 1) 
LDFLAGS+= -lstdc++ 
OBJ+=convolutional_kernels.o activation_kernels.o im2col_kernels.o col2im_kernels.o blas_kernels.o crop_layer_kernels.o dropout_layer_kernels.o maxpool_layer_kernels.o network_kernels.o avgpool_layer_kernels.o
endif

OBJS = $(addprefix $(OBJDIR), $(OBJ))
DEPS = $(wildcard src/*.h) Makefile

OBJS_CPP = $(addprefix $(OBJDIR_CPP), $(OBJ))

all: obj obj-cpp results $(EXEC) $(EXEC_CPP)

$(EXEC): obj clean $(OBJS)
	$(CC) $(COMMON) $(CFLAGS) $(OBJS) -o $@ $(LDFLAGS)

$(OBJDIR)%.o: %.c $(DEPS)
	$(CC) $(COMMON) $(CFLAGS) -c $< -o $@

$(EXEC_CPP): obj-cpp clean-cpp $(OBJS_CPP)
	$(CC_CPP) $(COMMON) $(CFLAGS) $(OBJS_CPP) -o $@ $(LDFLAGS)

$(OBJDIR_CPP)%.o: %.c $(DEPS_CPP)
	$(CC_CPP) $(COMMON) $(CFLAGS_CPP) $(CFLAGS) -c $< -o $@


$(OBJDIR)%.o: %.cu $(DEPS)
	$(NVCC) $(ARCH) $(COMMON) --compiler-options "$(CFLAGS)" -c $< -o $@

$(OBJDIR_CPP)%.o: %.cu $(DEPS)
	$(NVCC) $(ARCH) $(COMMON) --compiler-options "$(CFLAGS)" -c $< -o $@


obj:
	mkdir -p obj
obj-cpp:
	mkdir -p obj-cpp

results:
	mkdir -p results

.PHONY: clean

clean:
	rm -rf $(OBJS) $(EXEC)
clean-cpp:
	rm -rf $(OBJS_CPP) $(EXEC_CPP)

