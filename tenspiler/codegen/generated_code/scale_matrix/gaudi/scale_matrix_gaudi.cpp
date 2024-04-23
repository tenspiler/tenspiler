
#include <cstring>
// TODO: include your hpp file here

extern unsigned char _binary___scale_matrix_ps_gaudi2_o_start;
extern unsigned char _binary___scale_matrix_ps_gaudi2_o_end;


gcapi::GlueCodeReturn_t ScaleMatrixPsGaudi2::GetKernelName(
            char kernelName [gcapi::MAX_NODE_NAME])
{
    strcpy(kernelName,"custom_scale_matrix_ps_gaudi2");
    return gcapi::GLUE_SUCCESS;
}


gcapi::GlueCodeReturn_t ScaleMatrixPsGaudi2::GetGcDefinitions(
            gcapi::HabanaKernelParams_t* inDefs,
            gcapi::HabanaKernelInstantiation_t* outDefs) {
    gcapi::GlueCodeReturn_t retVal = setGcDefsHelper(
        inDefs,
        outDefs,
        1,
        2,
        gcapi::DATA_I32
        &_binary___scale_matrix_ps_gaudi2_o_start,
        &_binary___scale_matrix_ps_gaudi2_o_end,
    );

    // Define scalar params
    ScaleMatrixPsParam* paramDef = static_cast<ScaleMatrixPsParam*>(in_defs->NodeParams);
    out_defs->kernel.paramsNr = sizeof(*paramDef)/ sizeof(int32_t);
    memcpy(&(outDefs->kernel.scalarParams[0]), paramDef, sizeof(*paramDef));

    return retVal;
}