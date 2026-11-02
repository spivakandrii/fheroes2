// Object subscripting (dict[key], array[i]) compiles to iOS 6 selectors.
// Xcode links libarclite to add them on iOS 5; the Theos toolchain has no arclite,
// so add the missing methods at load time.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static id arrayObjectAtIndexedSubscript( NSArray * self, SEL _cmd, NSUInteger index )
{
    return [self objectAtIndex:index];
}

static void mutableArraySetObjectAtIndexedSubscript( NSMutableArray * self, SEL _cmd, id object, NSUInteger index )
{
    if ( index == [self count] ) {
        [self addObject:object];
    }
    else {
        [self replaceObjectAtIndex:index withObject:object];
    }
}

static id dictionaryObjectForKeyedSubscript( NSDictionary * self, SEL _cmd, id key )
{
    return [self objectForKey:key];
}

static void mutableDictionarySetObjectForKeyedSubscript( NSMutableDictionary * self, SEL _cmd, id object, id key )
{
    if ( object ) {
        [self setObject:object forKey:key];
    }
    else {
        [self removeObjectForKey:key];
    }
}

static void addIfMissing( Class cls, SEL sel, IMP imp, const char * types )
{
    if ( ![cls instancesRespondToSelector:sel] ) {
        class_addMethod( cls, sel, imp, types );
    }
}

__attribute__( ( constructor ) ) static void installSubscripting( void )
{
    addIfMissing( [NSArray class], @selector( objectAtIndexedSubscript: ), (IMP)arrayObjectAtIndexedSubscript, "@@:I" );
    addIfMissing( [NSMutableArray class], @selector( setObject:atIndexedSubscript: ), (IMP)mutableArraySetObjectAtIndexedSubscript, "v@:@I" );
    addIfMissing( [NSDictionary class], @selector( objectForKeyedSubscript: ), (IMP)dictionaryObjectForKeyedSubscript, "@@:@" );
    addIfMissing( [NSMutableDictionary class], @selector( setObject:forKeyedSubscript: ), (IMP)mutableDictionarySetObjectForKeyedSubscript, "v@:@@" );
}
