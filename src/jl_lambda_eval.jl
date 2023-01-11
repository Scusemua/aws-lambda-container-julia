__precompile__()

module julia_eval

using JSON

lambda_function(f::Function) = Base.invokelatest(f)

lambda_function(e::Expr) = eval(Main, e)

function lambda_function(v::Vector)
    for e in v[1:end-1]
        eval(Main, e)
    end
    eval(Main, v[end])
end


lambda_function_with_event(event::String) = include_string(event)


precompile(lambda_function, (Function,))
precompile(lambda_function, (Expr,))
precompile(lambda_function, (Vector{Expr},))
precompile(lambda_function_with_event, (String,))

function execute_code(input::String, output::IOStream)
    b64in = Base64DecodePipe(IOBuffer(input))
    b64out = Base64EncodePipe(output)
    serialize(b64out, lambda_function(deserialize(b64in)...))
    close(b64out)
end

function handle_event(event_data, headers)
    @info "Handling request" event_data headers

    if event_data isa Dict{String,Any} && haskey(event_data, "jl_data")
        execute_code(event_data["jl_data"], output)
    else
        JSON.print(output, lambda_function_with_event(event_data))

    return "success"
end

context() = JSON.parsefile("/tmp/lambda_context")

precompile(main, (Module,))
precompile(invoke_jl_lambda, (Module, String, IOStream))
precompile(invoke_lambda, (Module, String, IOStream))
precompile(invoke_lambda, (Module, Dict{String,Any}, IOStream))
precompile(invoke_lambda, (Module, Vector{Any}, IOStream))

end # module julia_eval


#==============================================================================#
# End of file.
#==============================================================================#
