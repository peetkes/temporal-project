xquery version "1.0-ml";

module namespace transform = "http://www.marklogic.com/temporal-project/mlcp/transforms/duplicate-check";

declare function transform:transform(
    $content as map:map,
    $context as map:map
) as map:map*
{
    let $node := map:get($content, "value")
    let $checksum := xdmp:md5($node)

    return (
        xdmp:lock-for-update($checksum),
        if (fn:empty((cts:element-words((xs:QName("checksum")),$checksum,("limit=1", "collation=http://marklogic.com/collation/codepoint"),cts:collection-query("raw")))))
        then (
            map:put($context, "collections", (map:get($context, "collections"), "raw")),
            map:put($content,"value", element envelope {
                element header {
                    element checksum { $checksum },
                    element systemStart {},
                    element systemEnd {}
                },
                element instance {
                    $content
                }
            }),
            $content
        )
        else xdmp:log("Duplicate detected for uri="||map:get($content,"uri"))
    )
};