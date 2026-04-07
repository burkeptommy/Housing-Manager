-- Fix utility provider logos: use PNG/JPEG instead of SVG (AsyncImage doesn't render SVG),
-- use symbol (transparent) instead of icon (opaque bg) where available,
-- and correct brand colors from fresh Brandfetch data.

-- Electric
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idM3_WsmWJ/w/800/h/800/theme/dark/symbol.png?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#00ae42' WHERE slug = 'eversource';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idt2cH-iXK/w/320/h/320/theme/dark/icon.png?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#1CBFFF' WHERE slug = 'national-grid';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idqEGAkMgq/w/400/h/400/theme/dark/icon.jpeg?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#0092cf' WHERE slug = 'conedison';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idjCCckzMf/w/800/h/832/theme/dark/symbol.png?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#26bcd7' WHERE slug = 'duke-energy';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idN3xLg16j/w/800/h/800/theme/dark/symbol.png?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#2f97da' WHERE slug = 'fpl';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idTl4NDozn/w/399/h/399/theme/dark/icon.jpeg?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#fbbb36' WHERE slug = 'pge';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idEMvWkiXQ/w/800/h/800/theme/dark/symbol.png?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#fed141' WHERE slug = 'sce';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idqMsOMext/w/800/h/924/theme/dark/symbol.png?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#FEDB00' WHERE slug = 'dominion-energy';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idb6TJIh8d/w/800/h/993/theme/dark/symbol.png?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#FF1A58' WHERE slug = 'entergy';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idMTO7EFGJ/w/400/h/400/theme/dark/icon.jpeg?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#180D67' WHERE slug = 'comed';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idSxPkJXtA/w/800/h/817/theme/dark/symbol.png?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#f37121' WHERE slug = 'pseg';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/id8ktHatip/w/800/h/799/theme/dark/symbol.png?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#DA1020' WHERE slug = 'xcel-energy';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idhMrMwe1Q/w/800/h/684/theme/dark/symbol.png?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#555555' WHERE slug = 'georgia-power';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idELLD1wt-/w/800/h/800/theme/dark/symbol.png?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#2a8dd4' WHERE slug = 'centerpoint';

-- Internet/Cable
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/id3elZ9Rhl/w/800/h/857/theme/dark/symbol.png?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#6138F5' WHERE slug = 'xfinity';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idOeDMky9u/w/800/h/1215/theme/dark/symbol.png?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#0073D1' WHERE slug = 'spectrum';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/id5Kd7HGot/w/400/h/400/theme/dark/icon.png?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#00a8e0' WHERE slug = 'att';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idXhrQrb5t/w/400/h/400/theme/dark/icon.jpeg?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#EE0000' WHERE slug = 'verizon-fios';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/id9-QI5PX1/w/400/h/400/theme/dark/icon.jpeg?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#E20074' WHERE slug = 'tmobile-home';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/id6O2oGzv-/w/800/h/817/theme/dark/symbol.webp?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#4285F4' WHERE slug = 'google-fiber';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/iddHc0Hb2b/w/800/h/800/theme/dark/symbol.webp?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#FF0037' WHERE slug = 'frontier';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/id65JQNvxP/w/240/h/240/theme/dark/icon.jpeg?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#00aaf4' WHERE slug = 'cox';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idhM5WMkv7/w/800/h/545/theme/dark/symbol.png?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#F66608' WHERE slug = 'optimum';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/id8JDYYjZk/w/612/h/101/theme/dark/logo.png?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#ba9d63' WHERE slug = 'starlink';

-- Security
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idNsiJjIPg/w/800/h/800/theme/dark/logo.png?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#0061aa' WHERE slug = 'adt';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idW5ahdeNS/w/400/h/400/theme/dark/icon.jpeg?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#05E5AF' WHERE slug = 'vivint';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idr_Z_T7tU/w/400/h/400/theme/dark/icon.jpeg?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#008cc1' WHERE slug = 'simplisafe';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idTO9WNNNX/w/400/h/400/theme/dark/icon.jpeg?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#1c9ad6' WHERE slug = 'ring';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idIvveWWRV/w/400/h/400/theme/dark/icon.jpeg?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#17824a' WHERE slug = 'brinks-home';

-- Trash
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idpfh3Y_Ht/w/480/h/480/theme/dark/icon.jpeg?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#E8F733' WHERE slug = 'waste-management';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idwo2p7Mcu/w/800/h/775/theme/dark/symbol.png?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#D80125' WHERE slug = 'republic-services';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/id7VrGriT1/w/2048/h/2048/theme/dark/icon.jpeg?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#00263e' WHERE slug = 'casella';

-- Fuel
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idQNXRmKLN/w/400/h/400/theme/dark/icon.jpeg?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#e41e2d' WHERE slug = 'suburban-propane';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/id-Xb9wW8p/w/1500/h/1500/theme/dark/icon.jpeg?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#1e4ca1' WHERE slug = 'amerigas';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idRvkzIHpK/w/320/h/320/theme/dark/icon.jpeg?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#00599b' WHERE slug = 'ferrellgas';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idMDRhL2Nk/w/400/h/400/theme/dark/icon.jpeg?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#fdb924' WHERE slug = 'petro-home';

-- Water
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/id3QiYLdX7/w/720/h/720/theme/dark/icon.jpeg?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#00457c' WHERE slug = 'aquarion';
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/id2TVqqwD4/w/400/h/400/theme/dark/icon.jpeg?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#2fa2fb' WHERE slug = 'american-water';

-- Gas
UPDATE utility_providers SET logo_url = 'https://cdn.brandfetch.io/idEwvRCSvh/w/800/h/1463/theme/dark/symbol.png?c=1bxw03re11lkoxgmt5q5lkxm5swzQrR01JO', brand_color = '#93ADFF' WHERE slug = 'socalgas';
