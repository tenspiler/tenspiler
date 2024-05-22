
#ifndef _ARRAY_SUM_PS_GAUDI2_HPP
#define _ARRAY_SUM_PS_GAUDI2_HPP

#include "gc_interface.h"

class ArraySumPsGaudi2
{
    public:
        ArraySumPsGaudi2() {}
        virtual ~ArraySumPsGaudi2() {}

        virtual gcapi::GlueCodeReturn_t
        GetGcDefinitions(gcapi::HabanaKernelParams_t* inDefs,
                    gcapi::HabanaKernelInstantiation_t* outDefs);

        virtual gcapi::GlueCodeReturn_t GetKernelName(
                char kernelName [gcapi::MAX_NODE_NAME]);


    private:
        ArraySumPsGaudi2(const ArraySumPsGaudi2& other) = delete;
        ArraySumPsGaudi2& operator=(const ArraySumPsGaudi2& other) = delete;
};

#endif