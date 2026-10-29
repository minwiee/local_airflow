{#-
/*
*----------------------------------------------------------------------*
* Program code  : translate_vietnamese_accent_macro
* Program name  : translate_vietnamese_accent_macro
* Created by    : ducnm
* Created date  : 2025-10-30
*----------------------------------------------------------------------*
* Modified management
* Date        User          Jira 				Description
* 2025-10-30  ducnm       DWH-014		Init
*----------------------------------------------------------------------*
*/

-#}
{#- 
    Từ cột cần biến đổi ký tự tiếng Việt sang tiếng Anh -> loại bỏ các ký tự có dấu thành không dấu bằng hàm translate
    Ví dụ trong model bi_branch_info_intf__mnp: , {{ translate_vietnamese_accent_macro('ba.area_name') }}::varchar(255) as zone_name_new
    trong đó ba.area_name là cột cần biến đổi ký tự 
-#}

{% macro translate_vietnamese_accent_macro(input_str) %}
    translate(
        {{ input_str }}
        , 'áàảãạâấầẩẫậăắằẳẵặđéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵÁÀẢÃẠÂẤẦẨẪẬĂẮẰẲẴẶĐÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸỴ'
        , 'aaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyAAAAAAAAAAAAAAAAADEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYY'
    )
{% endmacro %}
