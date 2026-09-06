import { i18nBuilder  } from "keycloakify/login";
import type { ThemeName } from "../kc.gen";

const { useI18n, ofTypeI18n } = i18nBuilder
    .withThemeName<ThemeName>()
    .withExtraLanguages({
        xn: {
            label: "Arnie",
            getMessages: () => import("./i18.xn")
        }
    })
    .withCustomTranslations({
        en: {
            locale_xn: "Arnie",
        }
    })
    .build()

type I18n = typeof ofTypeI18n;
export { useI18n, type I18n };
