#pragma once

namespace Simple
{

#define DEFINE1 1

const int ConstGlobal1 = 1;

class CppClass
{
    int field3Value = 3;
public:
    int field1 = 1;
    int field2 = 2;
    int* field3;
    int field4[1] = {4};

    CppClass() {
        this->field3 = &this->field3Value;
    }

    int method1(int arg)
    {
        return 1 + arg;
    }

    int method2(int arg)
    {
        return 2 + arg;
    }

    int method3()
    {
        return 3;
    }

    void method4(int& arg)
    {
        arg = 4;
    }

    class CppNestedClass
    {
    public:
        int nestedField1 = 1;
    };
};

enum CPP_ENUM
{
    CPP_ENUM_MEMBER_1 = 1
};

inline int function1(CppClass instance)
{
    return 1 + instance.field1;
}

}
