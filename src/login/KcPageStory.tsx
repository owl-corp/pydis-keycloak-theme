import type { DeepPartial } from "keycloakify/tools/DeepPartial";
import type { KcContext } from "./KcContext";
import KcPage from "./KcPage";
import { createGetKcContextMock } from "keycloakify/login/KcContext";
import type { KcContextExtension, KcContextExtensionPerPage } from "./KcContext";
import { themeNames, kcEnvDefaults } from "../kc.gen";

const kcContextExtension: KcContextExtension = {
    themeName: themeNames[0],
    properties: {
        ...kcEnvDefaults
    },
    realm: {
        displayNameHtml: '<div class="kc-logo-text"><span>Python Discord</span></div>',
    }
};
const kcContextExtensionPerPage: KcContextExtensionPerPage = {};

export const { getKcContextMock } = createGetKcContextMock({
    kcContextExtension,
    kcContextExtensionPerPage,
    overrides: {},
    overridesPerPage: {}
});

function getKcLocaleFromUrl(): string | undefined {
    if (typeof window === "undefined") return undefined;
    const searchParams = new URLSearchParams(window.location.search);
    return searchParams.get("kc_locale") ?? undefined;
}

function buildLanguageUrl(languageTag: string): string {
    if (typeof window === "undefined") return `?kc_locale=${languageTag}`;
    const searchParams = new URLSearchParams(window.location.search);
    searchParams.set("kc_locale", languageTag);
    return `?${searchParams.toString()}`;
}

export function createKcPageStory<PageId extends KcContext["pageId"]>(params: {
    pageId: PageId;
}) {
    const { pageId } = params;

    function KcPageStory(props: {
        kcContext?: DeepPartial<Extract<KcContext, { pageId: PageId }>>;
    }) {
        const { kcContext: overrides } = props;
        const overridesRecord = overrides as Record<string, any> | undefined;

        const currentLanguageTag =
            getKcLocaleFromUrl() ??
            (overridesRecord?.locale?.currentLanguageTag as string | undefined) ??
            "en";

        const supportedLanguages = [
            { languageTag: "en", label: "English" },
            { languageTag: "xn", label: "Arnie" },
            { languageTag: "fr", label: "Français" },
            { languageTag: "de", label: "Deutsch" },
            { languageTag: "es", label: "Español" }
        ].map(lang => ({
            ...lang,
            url: buildLanguageUrl(lang.languageTag)
        }));

        const kcContextMock = getKcContextMock({
            pageId,
            overrides: {
                ...overridesRecord,
                locale: {
                    currentLanguageTag,
                    supported: supportedLanguages,
                    ...(overridesRecord?.locale ?? {})
                }
            } as any
        });

        return <KcPage kcContext={kcContextMock} />;
    }

    return { KcPageStory };
}
