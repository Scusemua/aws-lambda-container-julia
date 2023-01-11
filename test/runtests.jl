using .jl_lambda_eval
using Test
using Serialization

function test_func() 
    run(`uname -snr`)
end

@testset "jl_lambda_eval.jl" begin
    serialized_payload = jl_lambda_eval.serialize64(test_func)
    result = jl_lambda_eval.handle_event(Dict("jl_data" => serialized_payload), String[])
    @test result isa String
end
