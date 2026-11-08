-- نفّذ هذا الملف من Supabase > SQL Editor بعد إنشاء الجداول الأساسية.
-- يفترض وجود الجداول: categories(id,name) و products(id,category_id,name,brand,description,price,stock,image_url,is_active,created_at)

-- إنشاء قائمة المديرين. لا تسمح للزوار بإضافة أنفسهم كمدير.
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;
grant select on public.admin_users to authenticated;
drop policy if exists "admins_read_own_admin_record" on public.admin_users;
create policy "admins_read_own_admin_record"
on public.admin_users for select to authenticated
using (user_id = auth.uid());

-- السماح للمستخدم المسجل كمدير فقط بإضافة/تعديل/حذف المنتجات.
grant insert, update, delete on public.products to authenticated;
drop policy if exists "admins_manage_products" on public.products;
create policy "admins_manage_products"
on public.products for all to authenticated
using (exists (select 1 from public.admin_users au where au.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users au where au.user_id = auth.uid()));

-- أقسام تجريبية تُضاف فقط إذا كان جدول الأقسام فارغاً.
do $$
begin
  if not exists (select 1 from public.categories limit 1) then
    insert into public.categories(name)
    values ('موبايلات'), ('سماعات'), ('ساعات ذكية'), ('إكسسوارات');
  end if;
end $$;

-- ملاحظة: احتفظ بسياسات القراءة العامة الحالية للأقسام والمنتجات النشطة.
