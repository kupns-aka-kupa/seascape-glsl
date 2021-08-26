#ifndef GSL_VIEW_SHADER_HPP
#define GSL_VIEW_SHADER_HPP

#include <glad/glad.h>

#include <string>
#include <fstream>
#include <sstream>
#include <iostream>
#include <utility>
#include <tuple>

class Shader
{
public:
    uint32_t ProgramId;

    Shader(const char* vertexPath, const char* fragmentPath);
    void use();

    // ------------------------------------------------------------------------
    template<class... Args>
    constexpr void setInt(const std::string &name, Args... args) const
    {
        auto&& args_tuple = std::forward_as_tuple(std::forward<Args>(args)...);
        auto location = glGetUniformLocation(ProgramId, name.c_str());
        constexpr auto size = sizeof...(Args);

        if constexpr (size == 1)
        {
            return glUniform1i(location,
                               std::get<0>(args_tuple));
        }
        else if constexpr (size == 2)
        {
            return glUniform2i(location,
                               std::get<0>(args_tuple),
                               std::get<1>(args_tuple));
        }
        else if constexpr (size == 3)
        {
            return glUniform3i(location,
                               std::get<0>(args_tuple),
                               std::get<1>(args_tuple),
                               std::get<2>(args_tuple));
        }
        else if constexpr (size == 4)
        {
            return glUniform4i(location,
                               std::get<0>(args_tuple),
                               std::get<1>(args_tuple),
                               std::get<2>(args_tuple),
                               std::get<3>(args_tuple));
        }
    }

    template<class... Args>
    constexpr void setFloat(const std::string &name, Args... args) const
    {
        auto&& args_tuple = std::forward_as_tuple(std::forward<Args>(args)...);
        auto location = glGetUniformLocation(ProgramId, name.c_str());
        constexpr auto size = sizeof...(Args);

        if constexpr (size == 1)
        {
            return glUniform1f(location,
                               std::get<0>(args_tuple));
        }
        else if constexpr (size == 2)
        {
            return glUniform2f(location,
                               std::get<0>(args_tuple),
                               std::get<1>(args_tuple));
        }
        else if constexpr (size == 3)
        {
            return glUniform3f(location,
                               std::get<0>(args_tuple),
                               std::get<1>(args_tuple),
                               std::get<2>(args_tuple));
        }
        else if constexpr (size == 4)
        {
            return glUniform4f(location,
                               std::get<0>(args_tuple),
                               std::get<1>(args_tuple),
                               std::get<2>(args_tuple),
                               std::get<3>(args_tuple));
        }
    }

private:
    void checkCompileErrors(uint32_t shader, std::string type);
};

#endif //GSL_VIEW_SHADER_HPP
