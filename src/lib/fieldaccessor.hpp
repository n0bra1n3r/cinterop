template<typename Cls, typename Ret>
struct MemberWrapper
{
    using Type = Ret(Cls::*);
};

template<class Tag, class Wrapper>
struct Proxy
{
    static typename Wrapper::Type value;
};

template <class Tag, class Wrapper>
typename Wrapper::Type Proxy<Tag, Wrapper>::value;

template<class Wrapper, typename Wrapper::Type AccessPointer>
class MakeProxy
{
    struct Setter
    {
        Setter() {
            Proxy<Wrapper, Wrapper>::value = AccessPointer;
        }
    };

    static Setter instance;
};

template<class Wrapper, typename Wrapper::Type AccessPointer>
typename MakeProxy<Wrapper, AccessPointer>::Setter MakeProxy<Wrapper, AccessPointer>::instance;
