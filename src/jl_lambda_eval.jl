__precompile__()

module jl_lambda_eval 

using JSON
using Base64
using Serialization

# Base64 representation of Julia objects...

function serialize64(x)
    buf = IOBuffer()
    b64 = Base64.Base64EncodePipe(buf)
    serialize(b64, x)
    close(b64)
    String(take!(buf))
end

lambda_function(f::Function) = Base.invokelatest(f)

lambda_function(e::Expr) = eval(Main, e)

function lambda_function(v::Vector)
    for e in v[1:end-1]
        eval(Main, e)
    end
    eval(Main, v[end])
end

lambda_function_with_event(event::String) = include_string(Main, event)

function execute_code(input::String)
    b64in = Base64.Base64DecodePipe(IOBuffer(input))
    code = deserialize(b64in)
    Base.invokelatest(code)
    result = lambda_function(code)
    
    return result
end

function handle_event(event_data, headers)
    @info "Handling request" event_data headers

    if isa(event_data, Dict) && haskey(event_data, "jl_data")
        execute_code(event_data["jl_data"])
    else
        JSON.print(Base.stdout, lambda_function_with_event(event_data))
    end

    return "success"
end

context() = JSON.parsefile("/tmp/lambda_context")

precompile(lambda_function, (Function,))
precompile(lambda_function, (Expr,))
precompile(lambda_function, (Vector{Expr},))
precompile(lambda_function_with_event, (String,))

end # module jl_lambda_eval

#==============================================================================#
# End of file.
#==============================================================================#