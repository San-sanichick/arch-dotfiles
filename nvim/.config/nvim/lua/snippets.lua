local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node

ls.add_snippets("vue", {
    s("template", {
        t({ "<template>", "\t" }),
        i(1),
        t({ "", "</template>" })
    }),
    s("scrsetup", {
        t({ '<script setup lang="ts">', "\t" }),
        i(1),
        t({ "", "</script>" })
    }),
    s("props", {
        t({ "const props = defineProps<{", "\t" }),
        i(1),
        t({ "", "}>();" })
    }),
    s("defprops", {
        t("const props = withDefaults(defineProps<{"),
        i(1),
        t({ "}>(), {" }),
        i(2),
        t({ "});" })
    }),
    s("emits", {
        t({ "const emit = defineEmits<{", "\t" }),
        i(1),
        t({ "", "}>();" })
    }),

    s("vfor", {
        t('v-for="('),
        i(1, "item"),
        t(', '),
        i(2, "index"),
        t(') in '),
        i(3, "list"),
        t('" :key="'),
        i(4, "index"),
        t('"')
    }),

    s("vif", {
        t('v-if="'),
        i(1, "cond"),
        t('"')
    }),

    s("velif", {
        t('v-else-if="'),
        i(1, "cond"),
        t('"')
    }),

    s("vel", {
        t('v-else')
    }),
})


ls.add_snippets("javascript", {
    s("clg", {
        t("console.log("), i(1), t(")")
    }),
    s("cer", {
        t("console.error("), i(1), t(")")
    }),
    s("cas", {
        t("console.assert("), i(1), t(", "), i(2), t(")")
    }),
    s("ccl", {
        t("console.clear()")
    }),
    s("cco", {
        t("console.count("), i(1), t(")")
    }),
    s("cdb", {
        t("console.debug("), i(1), t(")")
    }),
    s("cdi", {
        t("console.dir("), i(1), t(")")
    }),
    s("cgr", {
        t("console.group("), i(1), t(")")
    }),
    s("cge", {
        t("console.groupEnd()")
    }),
    s("cwa", {
        t("console.warn("), i(1), t(")")
    }),
    s("cin", {
        t("console.info("), i(1), t(")")
    }),
    s("clt", {
        t("console.table("), i(1), t(")")
    }),
    s("cti", {
        t("console.time("), i(1), t(")")
    }),
    s("cte", {
        t("console.timeEnd("), i(1), t(")")
    }),

    s("trycatch", {
        t({ "try", "{", "\t" }),
        i(1),
        t({ "", "}", "catch(" }),
        i(2, "error"),
        t({ ")", "" }),
        t({ "{", "\t" }),
        t("console.error("),
        i(3, "error"),
        t(")"),
        t({ "", "}" })
    }),

    s("switch", {
        t({ "switch (" }),
        i(1, "val"),
        t({ ")", "{", "\t" }),
        t({ "case " }),
        i(2, "case1"),
        t({ ": break;", "\t" }),
        t("default: break;"),
        t({ "", "}" })
    }),

    -- s("@", {
    --     t("// @ts-ignore")
    -- }),

    s("#", {
        t("//#region")
    }),

    s("#", {
        t("//#endregion")
    }),
})


ls.filetype_extend("typescriptreact", { "javascript" })
ls.filetype_extend("typescript", { "javascript" })
ls.filetype_extend("vue", { "javascript" })

